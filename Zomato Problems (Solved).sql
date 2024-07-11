drop table if exists goldusers_signup;
CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'09-22-2017'),
(3,'04-21-2017');

drop table if exists users;
CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'09-02-2014'),
(2,'01-15-2015'),
(3,'04-11-2014');

drop table if exists sales;
CREATE TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'04-19-2017',2),
(3,'12-18-2019',1),
(2,'07-20-2020',3),
(1,'10-23-2019',2),
(1,'03-19-2018',3),
(3,'12-20-2016',2),
(1,'11-09-2016',1),
(1,'05-20-2016',3),
(2,'09-24-2017',1),
(1,'03-11-2017',2),
(1,'03-11-2016',1),
(3,'11-10-2016',1),
(3,'12-07-2017',2),
(3,'12-15-2016',2),
(2,'11-08-2017',2),
(2,'09-10-2018',3);


drop table if exists product;
CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);


select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;



1 ---- what is total amount each customer spent on zomato ?

select a.userid,sum(b.price) total_amt_spent from sales a inner join product b on a.product_id=b.product_id
group by a.userid

/* Alternative */
	
select s.userid, sum(p.price) as total_amt_spent from sales s
	join product p on s.product_id = p.product_id
	group by s.userid
	order by sum(p.price) desc



2 ---- How many days has each customer visited zomato?


select userid,count(created_date) as total_visits from sales
group by userid
	order by userid

3 --- what was the first product purchased by each customer?

select userid, created_date first_order_date, product_id
	from (select *, row_number() over (partition by userid order by created_date) rn
	from sales) 
	where rn = 1
	
4 --- what is most purchased item on menu & how many times was it purchased by all customers ?

select userid,count(product_id) purchase_count from sales where product_id in
(select  product_id from sales group by product_id order by count(product_id) desc 
	limit 1)
group by userid

	
5 ---- which item was most popular for each customer?

select userid,product_id,cnt from
(select *,rank() over(partition by userid order by cnt desc) rnk from
(select userid,product_id,count(product_id) cnt from sales group by userid,product_id))
where rnk =1


6 --- which item was purchased first by customer after they become a member ?

select * from
(select *,rank() over (partition by userid order by created_date ) rnk from
(select a.userid,b.gold_signup_date,a.created_date,a.product_id from sales a join 
goldusers_signup b on a.userid=b.userid where a.created_date>=b.gold_signup_date))
	where rnk=1;


7 --- which item was purchased just before customer became a member?

select * from
(select *,rank() over (partition by userid order by created_date desc ) rnk from
(select a.userid,a.created_date,a.product_id,b.gold_signup_date from sales a inner join 
goldusers_signup b on a.userid=b.userid and created_date<=gold_signup_date))
	where rnk=1;


8 ---- what is total orders and amount spent for each member before they become a member ?

select e.userid,count(e.created_date) order_purchased,sum(e.price) total_amt_spent from
((select a.userid,a.created_date,a.product_id,b.gold_signup_date from sales a  join 
goldusers_signup b on a.userid=b.userid where a.created_date<=b.gold_signup_date) c
	join product d on c.product_id=d.product_id) e
group by e.userid;


9 --- in the first one year after customer joins the gold program (including the join date )
	--- irrespective of what customer has purchased earn 5 zomato points for every
	---	10 rs spent who earned more more 1 or 3  
   -- what int earning in first yr ? 1zp = 2rs

select c.*,d.price*0.5 total_points_earned from
((select a.userid,a.created_date,a.product_id,b.gold_signup_date from sales a inner join
goldusers_signup b on a.userid=b.userid where a.created_date>=b.gold_signup_date
	and a.created_date<=b.gold_signup_date + interval '1 year')c
inner join product d on c.product_id=d.product_id)



10 --- rnk all transaction of the customers


select*, rank() over (partition by userid order by created_date ) rnk from sales
	
/* Alternative method */
	
select userid, created_date, product_id
	from sales order by userid,created_date

11 --- rank all transaction for each member whenever they are zomato gold member
	---	for every non gold member transaction mark as na

select e.*,case when rnk=0 then 'na' else cast(rnk as varchar) end as rnkk from
(select c.*,case when gold_signup_date is null then 0
	else rank() over (partition by userid order by created_date desc) end rnk
	from
(select a.userid,a.created_date,a.product_id,b.gold_signup_date from sales a left join
goldusers_signup b on a.userid=b.userid and created_date>=gold_signup_date)c)e;