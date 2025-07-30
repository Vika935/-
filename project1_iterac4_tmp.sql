/* Проект «Секреты Тёмнолесья»
 * Цель проекта: изучить влияние характеристик игроков и их игровых персонажей 
 * на покупку внутриигровой валюты «райские лепестки», а также оценить 
 * активность игроков при совершении внутриигровых покупок
 * 
 * Автор:КРАСАВЦЕВА ВИКТОРИЯ ИГОРЕВНА  
 * Дата: 3.12.2024
*/

-- Часть 1. Исследовательский анализ данных
-- Задача 1. Исследование доли платящих игроков

-- 1.1. Доля платящих пользователей по всем данным:
with tab1 AS(select count(distinct id) as total_users --сначала я нашла общее число пользователей
from fantasy.users),
tab2 as (select count (distinct id) as pay_users
from fantasy.users 
where payer=1) --тут определила кто из них платит 
select *, round(pay_users::numeric/total_users::numeric,4) as fraction_users
from tab1,tab2; 

-- 1.2. Доля платящих пользователей в разрезе расы персонажа:
SELECT r.race,COUNT(payer) as kol_users,--кол-во пользователей  
SUM(payer) as pay_users, 
AVG(payer) as avg_users
FROM fantasy.users u
join fantasy.race r on u.race_id=r.race_id
group by r.race;

-- Задача 2. Исследование внутриигровых покупок
-- 2.1. Статистические показатели по полю amount:
select count(amount) as total_amount ,--советшено транзакций
		sum(amount) as sum_amount,--сумма транзакций
		min(amount) as min_amount,--минимальная стоимость 
		max(amount) as max_amount,--максимальная стоимость
		avg(amount) as avg_amount,--средняя стоимость 
		PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY amount) as mediana_amount,--медиана
		stddev(amount) as st_amount--размах
from fantasy.events e
where amount<>0;

-- 2.2: Аномальные нулевые покупки:
with nul as
(select count(amount) as kol_pok_abs0
from fantasy.events e 
where amount=0
 )
select count(amount) as kol_pok, kol_pok_abs0,kol_pok_abs0 / count(amount)::numeric as doly--исправила расчеты и поменяла местами 
from fantasy.events, nul
group by kol_pok_abs0;

-- 2.3: Сравнительный анализ активности платящих и неплатящих игроков:
select count(distinct u.id) as total_inc_users,--число уникальных играков 
	   count(u.id)::numeric/count(distinct u.id) as avg_purchas,--среднее число покупок 
		sum(amount)::numeric/count(distinct u.id) as avg_trata--добавила средние суммарные траты на игрока
from fantasy.events e
join fantasy.users u on e.id=u.id
where amount>0-- поменяла значение фильтра 
group by payer;

-- 2.4: Популярные эпические предметы:
with tab1 as (select i.game_items,e.item_code,count(transaction_id) as count_trans--кол-во транзакций 
from fantasy.events e
join fantasy.items i on e.item_code =i.item_code
where amount>0
group by i.game_items,e.item_code) ,tab2 as (
select i.game_items,e.item_code ,COUNT(DISTINCT e.id) as kol_uniq--кол-во уникальных игроков
FROM fantasy.events e
join fantasy.items i on e.item_code =i.item_code
where amount>0
group by i.game_items,e.item_code)
select i.game_items,e.item_code, count(distinct e.id) as total_inq_users, --кол-во уникальных пользователей   
count(distinct t u.id)::numeric/(select count(distinct id) from fantasy.events e) as doly_kup,--доля купивших
count(t1.count_trans)::numeric/(select count(amount) from fantasy.events) as doly_tranz--доля по транзакциям
from fantasy.events e 
join fantasy.users u on e.id =u.id 
join fantasy.items i on e.item_code =i.item_code
join tab1 as t1 on e.item_code =t1.item_code
join tab2 as t2 on e.item_code =t2.item_code
group by i.game_items,t1.count_trans,t2.kol_uniq,e.item_code
order by count_trans desc; 

-- Часть 2. Решение ad hoc-задач
-- Задача 1. Зависимость активности игроков от расы персонажа:
with tab1 as (select r.race, count(u.id) as total_users--число игроков в расе
from fantasy.users u 
join fantasy.race r on u.race_id=r.race_id
group by r.race),
tab2 as(select r.race,count(distinct e.id) as total_pay_users--которые купили 
from fantasy.events e 
join fantasy.users u on e.id=u.id
join fantasy.race r on u.race_id=r.race_id
group by r.race ),
tab3 as (select r.race,count(distinct u.id) as uniq--уникальные пользователи в расе
from fantasy.users u 
join fantasy.race r on u.race_id=r.race_id
join fantasy.events e on u.id=e.id
where payer=1
group by r.race),
tab4 as(select r.race,count(transaction_id) as total_transaction,--число транзакций
sum(amount) as sum_pok--сумма покупок в расе 
from fantasy.events e 
join fantasy.users u on e.id=u.id
join fantasy.race r on u.race_id=r.race_id
group by r.race)
select r.race,total_users,total_pay_users,uniq,total_transaction,
t2.total_pay_users::numeric/ t1.total_users as doly_kyp_users,--доля купивших играков
t3.uniq::numeric /total_pay_users as doly_plat_users,--доля платящих
total_transaction::numeric /total_pay_users as avg_count_pok,--среднее число покупок в расе 
sum_pok::numeric /total_pay_users as avg_sum_pok,--средняя суммарная стоимость покупок 
sum_pok::numeric / total_transaction as avg_chislo_pok--средняя стоимость покупки 
from fantasy.events e 
join fantasy.users u on e.id=u.id
join fantasy.race r on u.race_id=r.race_id
join tab1 as t1 on r.race =t1.race
join tab2 as t2 on r.race =t2.race
join tab3 as t3 on r.race =t3.race
join tab4 as t4 on r.race =t4.race
group by r.race,t1.total_users,t2.total_pay_users,t3.uniq,t4.total_transaction,t4.sum_pok;
