use paypal_transaction;
desc countries;
desc currencies;
desc merchants;
desc transactions;

desc users;
select * from users;

update users
set account_creation_date = str_to_date(account_creation_date, '%Y-%m-%d %H:%i:%s');
alter table users
modify account_creation_date datetime;

select * from countries;
select * from transactions;
select * from currencies;
select * from merchants;

-- Identify top 5 countries transaction between (oct- nov) 2023
select country_name, round(sum(transaction_amount),2) as totaltransaction
from transactions t
join users u
on t.recipient_id = u.user_id
join countries c
on u.country_id = c.country_id
where quarter(t.transaction_date) = 4 and year(t.transaction_date) = 2023
group by country_name
order by totaltransaction desc
limit 5;

-- top 10 merchants transaction for last one year
select m.merchant_id, m.business_name, round(sum(t.transaction_amount), 2) as total_recieved, round(avg(transaction_amount), 2) as average_transaction
from transactions t
join merchants m
on t.recipient_id = m.merchant_id
where t.transaction_date between '2023-11-01' and '2024-04-30'
group by m.merchant_id, m.business_name
order by total_recieved desc
limit 10;		

-- top 3 countrie's currency code in which amount transacted
select t.currency_code, round(sum(t.transaction_amount), 2) as total_converted
from transactions t
where t.transaction_date between '2023-05-22' and '2024-05-22'
group by t.currency_code
order by total_converted desc
limit 3;
 
 -- total amount falls under high value and regular category
select case when transaction_amount > 10000 then 'High value' 
	else 'regular'
end as transaction_category, round(sum(transaction_amount), 2) as total_amount
from transactions
where year(transaction_date) = 2023
group by transaction_category;

-- user's details who had made purchased more than average amount 5000
select u.user_id, u.email, round(avg(t.transaction_amount), 2) as avg_amount
from users u
join transactions t
on u.user_id = t.sender_id
where t.transaction_date between '2023-11-01' and '2024-05-01'
group by u.user_id, u.email
having avg_amount > 5000
order by u.user_id;

-- monthly trends of amount transacted in year 2023
select year(transaction_date) as transaction_year, month(transaction_date) as transaction_month, round(sum(transaction_amount), 2) as total_amount
from transactions
where year(transaction_date) = 2023
group by  year(transaction_date), month(transaction_date)
order by transaction_month;

-- loyal customer who has done the highest transaction amount for last one year
select u.user_id, u.email, u.name, round(sum(t.transaction_amount), 2) as total_amount
from users u
join transactions t
on u.user_id = t.sender_id
where t.transaction_date between '2023-05-22' and '2024-05-22'
group by  u.user_id, u.email, u.name
order by total_amount desc
limit 1;

-- performance of merchants in the basis of total_recieved amount 
SELECT merchant_id, business_name, round(SUM(t.transaction_amount),2) AS total_received, 
      CASE
          WHEN SUM(t.transaction_amount) > 50000 THEN 'Excellent'
          WHEN SUM(t.transaction_amount) > 20000 THEN 'Good'
          WHEN SUM(t.transaction_amount) > 10000 THEN 'Average'
          ELSE 'Below Average'
      END AS performance_score,round(AVG(t.transaction_amount),2) AS average_transaction 
FROM transactions t
JOIN merchants m ON t.recipient_id = m.merchant_id
WHERE t.transaction_date >= '2023-11-01' AND t.transaction_date < '2024-05-01'
GROUP BY m.merchant_id, m.business_name
ORDER BY
      CASE performance_score
          WHEN 'Excellent' THEN 1
          WHEN 'Good' THEN 2
          WHEN 'Average' THEN 3
      ELSE 4 END,
      total_received DESC;

-- categorize merchants performance on the basis of total transaction amount more than 50000
select m.merchant_id, m.business_name, year(t.transaction_date) as transaction_year, month(t.transaction_date) as transaction_month , round(sum(t.transaction_amount), 2) as total_transaction_amount,
case when sum(t.transaction_amount) > 50000 then 'Exceeded $50000'
else 'Did not exceed $50000'
end as performance_status
from transactions t
join merchants m
on t.recipient_id = m.merchant_id
where t.transaction_date >= '2023-11-01' and t.transaction_date < '2024-05-02'
group by m.merchant_id, m.business_name, transaction_year, transaction_month
order by m.merchant_id, transaction_year, transaction_month;

-- geographic analysis of no. of transactions
select Case
                When U1.country_id != U2.country_id then 'International'
                else 'Domestic'
          End as transaction_type,
          count(*) as transaction_count
from Users U1
join transactions T 
on T.sender_id = U1.user_id 
join Users U2 
on T.recipient_id = U2.user_id
where T.transaction_date >= '2024-01-01' 
    AND T.transaction_date < '2024-04-01'
group by transaction_type;

-- categorize users on the basis of transaction amount and geographically
select case when t.transaction_amount > 10000 and u1.country_id != u2.country_id then 'High Value International'
            when t.transaction_amount > 10000 and u1.country_id = u2.country_id then 'High Value Domestic'
            when t.transaction_amount < 10000 and u1.country_id != u2.country_id then 'Regular International'
          else 'Regular Domestic'
end as transaction_category, count(t.transaction_id) as transaction_count
from users u1
join transactions t
on u1.user_id = t.sender_id
join users u2
on t.recipient_id = u2.user_id
where year(t.transaction_date) = 2023
group by transaction_category;

-- user's details  who have made at least one transaction in at least 6 out of 12 months from May 2023 to April 2024
with user_transaction as (
                   select u.user_id, u.email, month(t.transaction_date) as months, count(t.transaction_id) as counts
                   from transactions t
                   join users u
                   on t.sender_id = u.user_id
                   where t.transaction_date >= '2023-05-01' and t.transaction_date <= '2024-04-30'
                   group by u.user_id, u.email, months
)
select ut.user_id, ut.email
from user_transaction ut
group by ut.user_id, ut.email
having count(ut.months) >= 6
order by ut.user_id;    



