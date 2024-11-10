-- Answer to Q.2

with rcb_batting as (
  select bl.Match_Id,Over_Id,Ball_Id,Innings_No from ball_by_ball bl
   join matches ma on bl.Match_Id=ma.Match_Id
  where Team_Batting=(select Team_Id from team where Team_Name='Royal Challengers Bangalore')
  and ma.Season_Id=1
  )
  
SELECT   
(select sum(Runs_scored) from 
batsman_scored a join rcb_batting b 
on a.Match_Id=b.Match_Id and a.Innings_No=b.Innings_No
and a.Over_Id=b.Over_Id and a.Ball_Id=b.Ball_Id) 
+
(select sum(Extra_Runs) from 
extra_runs c join rcb_batting b 
on c.Match_Id=b.Match_Id and c.Innings_No=b.Innings_No
and c.Over_Id=b.Over_Id and c.Ball_Id=b.Ball_Id) 
as total_runs_scored_by_rcb_in_season_1;

-- Answer to Q.3

with player_above_25_in_season_2 as(
select z.Player_Id from 
(SELECT Player_Id,TIMESTAMPDIFF(
          YEAR, 
          DOB, 
          STR_TO_DATE(CONCAT((SELECT Season_Year FROM season WHERE Season_Id = 2), '-01-01'), '%Y-%m-%d')
       ) AS age
FROM player) z
where z.age>25
),

matches_in_season_2 as ( 
 select e.Match_Id,e.Player_Id from 
 matches d join player_match e 
 on d.Match_Id=e.Match_Id
 where d.Season_Id=2
 )
 
 select count(distinct g.Player_Id) as players_above_age_25_in_season_2 
 from  player_above_25_in_season_2 f join matches_in_season_2 g 
 on f.Player_Id=g.Player_Id ;
 
 -- Answer to Q.4
 
 select count(*) as matches_won_by_rcb_in_season_1 from matches
 where Season_Id=1 and 
 Match_Winner=(select Team_Id from team where Team_Name='Royal Challengers Bangalore');
 
 -- Answer to Q.5 
 

with matches_in_last_4_seasons as(
 select bl.* from 
 ball_by_ball bl join matches ma 
 on bl.Match_Id=ma.Match_Id 
 where ma.Season_Id in (6,7,8,9)
 ), 

runs_and_balls_of_players as (
select xy.Striker,count(xy.Ball_Id) as total_balls,sum(xy.Runs_scored) as total_runs from 
(select mt.Ball_Id,mt.Striker,ba.Runs_scored from 
matches_in_last_4_seasons mt join batsman_scored ba 
on mt.Match_Id=ba.Match_Id and
mt.Over_Id=ba.Over_Id AND 
mt.Ball_Id=ba.Ball_Id and 
mt.Innings_No=ba.Innings_No ) xy 
group by xy.Striker 
)

select pl.Player_Name, ((ru.total_runs/ru.total_balls)*100) as strike_rate from 
player pl join runs_and_balls_of_players ru 
on pl.Player_Id=ru.Striker
order by strike_rate desc
limit 10;

-- Answer to Q.6

with runs_and_matches_of_players as (
select xy.Striker,count(distinct xy.Match_Id) as total_matches,sum(xy.Runs_scored) as total_runs from 
(select bl.Match_Id,bl.Striker,ba.Runs_scored from 
ball_by_ball bl join batsman_scored ba 
on bl.Match_Id=ba.Match_Id and
bl.Over_Id=ba.Over_Id AND 
bl.Ball_Id=ba.Ball_Id and 
bl.Innings_No=ba.Innings_No ) xy 
group by xy.Striker 
)

select pl.Player_Name, (ru.total_runs/ru.total_matches) as average from 
player pl join runs_and_matches_of_players ru 
on pl.Player_Id=ru.Striker;

-- Answer to Q.7



with bowler_wickets as (
select bw.Bowler,count(*) as total_wickets from 
(select wi.*,bl.Bowler from 
wicket_taken wi join ball_by_ball bl 
on wi.Match_Id=bl.Match_Id and 
wi.Over_Id=bl.Over_Id and 
wi.Ball_Id=bl.Ball_Id and 
wi.Innings_No=bl.Innings_No
where wi.Kind_Out in (1,2,4,6,7,8) ) bw 
group by bw.Bowler
),

bowler_matches as (
select Bowler, count(distinct Match_Id) as total_matches from 
ball_by_ball 
group by Bowler 
),

combine_table as ( 
select ms.Bowler,ms.total_matches,coalesce(ws.total_wickets,0) as total_wickets from 
bowler_matches ms join bowler_wickets ws 
on ms.Bowler=ws.Bowler 
)

select pl.Player_Name as Bowler_Name, (co.total_wickets/co.total_matches) as avg_wickets from  
combine_table co join player pl 
on co.Bowler=pl.Player_Id;

-- Answer to Q.8 

with runs_and_matches_of_players as (
select xy.Striker,count(distinct xy.Match_Id) as total_matches,sum(xy.Runs_scored) as total_runs from 
(select bl.Match_Id,bl.Striker,ba.Runs_scored from 
ball_by_ball bl join batsman_scored ba 
on bl.Match_Id=ba.Match_Id and
bl.Over_Id=ba.Over_Id AND 
bl.Ball_Id=ba.Ball_Id and 
bl.Innings_No=ba.Innings_No ) xy 
group by xy.Striker 
),

player_average as (
select pl.Player_Name, (ru.total_runs/ru.total_matches) as average from 
player pl join runs_and_matches_of_players ru 
on pl.Player_Id=ru.Striker
),

bowler_wickets as (
select bw.Bowler,count(*) as total_wickets from 
(select wi.*,bl.Bowler from 
wicket_taken wi join ball_by_ball bl 
on wi.Match_Id=bl.Match_Id and 
wi.Over_Id=bl.Over_Id and 
wi.Ball_Id=bl.Ball_Id and 
wi.Innings_No=bl.Innings_No
where wi.Kind_Out in (1,2,4,6,7,8) ) bw 
group by bw.Bowler
),

bowler_matches as (
select Bowler, count(distinct Match_Id) as total_matches from 
ball_by_ball 
group by Bowler 
),

combine_table as ( 
select ms.Bowler,ms.total_matches,coalesce(ws.total_wickets,0) as total_wickets from 
bowler_matches ms join bowler_wickets ws 
on ms.Bowler=ws.Bowler 
),

wickets_average as (
select pl.Player_Name as Bowler_Name, (co.total_wickets/co.total_matches) as avg_wickets from  
combine_table co join player pl 
on co.Bowler=pl.Player_Id 
),

combine_runs_wickets_average as (
select pa.Player_Name,pa.average as average_runs,wa.avg_wickets from 
player_average pa join wickets_average wa 
on pa.Player_Name=wa.Bowler_Name 
)

select Player_Name from 
combine_runs_wickets_average 
where average_runs >(select avg(average) from player_average)
and avg_wickets>(select avg(avg_wickets) from wickets_average);


-- Answer to Q.9

with rcb_matches as (
select ve.Venue_Name,ma.Match_Winner from 
matches ma join venue ve
on ma.Venue_Id=ve.Venue_Id 
where ma.Team_1 = (select Team_Id from team where Team_name='Royal Challengers Bangalore') 
or ma.Team_2=(select Team_Id from team where Team_name='Royal Challengers Bangalore') 
)

select Venue_name, SUM(Case when Match_Winner=(select Team_Id from team where Team_name='Royal Challengers Bangalore') 
                         Then 1 ELSE 0 end) as won_matches, 
                  SUM(Case when Match_Winner=(select Team_Id from team where Team_name='Royal Challengers Bangalore') 
                         Then 0 ELSE 1 end) as lost_matches
from rcb_matches 
group by Venue_Name;


-- Answer to Q.10


				
with bowler_wickets as (
select bw.Bowler,count(*) as total_wickets from 
(select wi.*,bl.Bowler from 
wicket_taken wi join ball_by_ball bl 
on wi.Match_Id=bl.Match_Id and 
wi.Over_Id=bl.Over_Id and 
wi.Ball_Id=bl.Ball_Id and 
wi.Innings_No=bl.Innings_No
where wi.Kind_Out in (1,2,4,6,7,8) ) bw 
group by bw.Bowler
)

select bs.Bowling_skill,sum(bw.total_wickets) as total_wickets from 
bowler_wickets bw join player pl on bw.Bowler=pl.Player_Id
join bowling_style bs on pl.Bowling_skill=bs.Bowling_Id
group by bs.Bowling_skill 
order by total_wickets desc;

-- Answer to Q.11

-- I broke this question into 2 parts.

-- Part A (Batting performance Status)

with RCB_batting_matches as (
select ball_by_ball.* , matches.Season_Id from 
ball_by_ball join matches on ball_by_ball.Match_Id=matches.Match_Id
where ball_by_ball.Team_Batting = (select Team_Id from team where Team_name='Royal Challengers Bangalore')
),

runs_by_season as (
select rbm.Season_Id,sum(ba.runs_scored) as rcb_runs from 
RCB_batting_matches rbm join batsman_scored ba
on rbm.Match_Id=ba.Match_Id and  
rbm.Over_Id=ba.Over_Id and 
rbm.Ball_Id=ba.Ball_Id and 
rbm.Innings_No=ba.Innings_No 
group by rbm.Season_Id
order by rbm.Season_Id
)

select Season_Id, rcb_runs, CASE WHEN rcb_runs>previous_runs then "Improved" else "Not Improved" end as status from 
(select *,lag(rcb_runs) over(order by Season_Id) as previous_runs 
from runs_by_season) a ;

-- Part B (bowling performance status)

with RCB_bowling_matches as (
select ball_by_ball.* , matches.Season_Id from 
ball_by_ball join matches on ball_by_ball.Match_Id=matches.Match_Id
where ball_by_ball.Team_Bowling = (select Team_Id from team where Team_name='Royal Challengers Bangalore')
) ,

wickets_by_season as (
select rbo.Season_Id,count(*) as rcb_wickets from 
RCB_bowling_matches rbo join wicket_taken wi 
on rbo.Match_Id=wi.Match_Id and 
rbo.Over_Id=wi.Over_Id and 
rbo.Ball_Id=wi.Ball_Id and 
rbo.Innings_No=wi.Innings_No
group by rbo.Season_Id
order by rbo.Season_Id
)

select Season_Id, rcb_wickets, CASE WHEN rcb_wickets>previous_wickets then "Improved" else "Not Improved" end
						       as status from 
(select *,lag(rcb_wickets) over(order by Season_Id) as previous_wickets 
from wickets_by_season) xyz;





-- Answer to Q.12 
/* In this question, I will consider 2 KPIs, that is avearge runs
scored per innings and given per innings in the last season to analyze both 
the batting and bowling performances. */

with last_season_rcb_matches as (
select bl.* from 
ball_by_ball bl join matches ma on 
bl.Match_Id=ma.Match_Id 
where ma.Season_Id in (6,7,8,9) and 
bl.Team_Batting=(select Team_Id from team where Team_Name='Royal Challengers Bangalore')
),

runs_matches as (
select ls.*,ba.runs_scored from 
last_season_rcb_matches ls join batsman_scored ba 
on ls.Match_Id=ba.Match_Id
and ls.Over_Id=ba.Over_Id 
and ls.Ball_Id=ba.Ball_Id
and ls.Innings_No=ba.Innings_No
),

total_runs_matches as( 
select count(distinct rm.Match_Id) as rcb_total_matches, sum(runs_scored) as rcb_total_runs from 
runs_matches rm )

select (rcb_total_runs/rcb_total_matches) as average_runs_scored_per_innings from total_runs_matches;

/* Now I will check for average runs given by the bowlers*/

with last_season_rcb_matches as (
select bl.* from 
ball_by_ball bl join matches ma on 
bl.Match_Id=ma.Match_Id 
where ma.Season_Id in (6,7,8,9) and 
bl.Team_Bowling=(select Team_Id from team where Team_Name='Royal Challengers Bangalore')
),

runs_matches as (
select ls.*,ba.runs_scored from 
last_season_rcb_matches ls join batsman_scored ba 
on ls.Match_Id=ba.Match_Id
and ls.Over_Id=ba.Over_Id 
and ls.Ball_Id=ba.Ball_Id
and ls.Innings_No=ba.Innings_No
),

total_runs_matches as( 
select count(distinct rm.Match_Id) as rcb_total_matches, sum(runs_scored) as rcb_total_runs_given from 
runs_matches rm )

select (rcb_total_runs_given/rcb_total_matches) as average_runs_given_oer_innings from total_runs_matches;

-- Answer to Q.13 

with matches_venues as ( 
select bal.*,venue.Venue_Name from 
ball_by_ball bal join matches  on 
bal.Match_Id=matches.Match_Id 
join venue on matches.Venue_Id=venue.Venue_Id
),

wicket_balls as (
select mv.* from 
matches_venues mv join wicket_taken wt
on mv.Match_Id=wt.Match_Id and 
mv.Over_Id=wt.Over_Id and 
mv.Ball_Id=wt.Ball_Id and 
mv.Innings_No=wt.Innings_No 
where wt.Kind_Out in (1,2,4,6,7,8)
),

bowler_data as (
select pl.Player_Name,wb.Venue_Name,count(distinct wb.Match_Id) as total_matches,count(*) as total_wickets from 
wicket_balls wb join player pl on 
pl.Player_Id=wb.Bowler 
group by pl.Player_Name,wb.Venue_Name),

abcd as (
select Player_Name,Venue_Name,(total_wickets/total_matches) as average_wicktes_by_each_bowler_in_each_venue from
bowler_data
)

select *,rank() over(partition by Venue_Name order by average_wicktes_by_each_bowler_in_each_venue desc) as rnk 
from abcd
order by Venue_Name desc,average_wicktes_by_each_bowler_in_each_venue desc;


-- Answer to Q.14 
/* To analyse this I will consider 3 batsman and 3 bowlers and analyse their performance in the last 3 seasons.

The 3 players which I am  considering are:- Virat Kohli,MS DHoni,Suresh Raina. */



with runs_balls as (
select bl.*,ba.runs_scored from 
ball_by_ball bl join batsman_scored ba 
on bl.Match_Id=ba.Match_Id
and bl.Over_Id=ba.Over_Id
and bl.Ball_Id=ba.Ball_Id
and bl.Innings_No=ba.Innings_No 
where bl.Striker in (select Player_Id from player where player_name in ('V Kohli','MS Dhoni','SK Raina'))
),

matches_last_3_seasons as (
select rb.*,matches.Season_Id from 
runs_balls rb join matches 
on rb.Match_Id=matches.Match_Id 
where matches.Season_Id in (7,8,9)
)

select pl.Player_Name,ml.Season_Id,sum(ml.runs_scored) as total_runs_in_season from 
matches_last_3_seasons ml join player pl 
on ml.Striker=pl.Player_Id
group by pl.Player_Name,ml.Season_Id
order by pl.Player_Name;

-- Answer to Q.15 
/* In this question we will select 3 venues and 3 players and analyse their performance in these 3 venues.
 The 3 players I considered are Virat Kohli, Suresh Raina and Ms Dhoni, and the 3 venues are 
 M Chinnaswamy Stadium, MA Chidambaram Stadium, Chepauk, Wankhede Stadium
 */
 
with runs_balls as (
select bl.*,ba.runs_scored from 
ball_by_ball bl join batsman_scored ba 
on bl.Match_Id=ba.Match_Id
and bl.Over_Id=ba.Over_Id
and bl.Ball_Id=ba.Ball_Id
and bl.Innings_No=ba.Innings_No 
where bl.Striker in (select Player_Id from player where player_name in ('V Kohli','MS Dhoni','SK Raina'))
),

matches_in_3_venues as (
select rb.*,ve.Venue_Name from 
runs_balls rb join matches 
on rb.Match_Id=matches.Match_Id 
join venue ve on matches.Venue_Id=ve.Venue_Id
where matches.Venue_Id in (1,4,8)
),

matches_runs as (
select pl.Player_Name,mi.Venue_Name,count(distinct mi.Match_Id) as total_matches,sum(mi.runs_scored) as total_runs from 
matches_in_3_venues mi join player pl 
on mi.Striker=pl.Player_Id 
group by pl.Player_Name,mi.Venue_Name
)

select Player_Name,Venue_Name,(total_runs/total_matches) as avergae 
from matches_runs; 



-- Subjective Questions 

-- Answer to Q.1 
select ve.Venue_Name,sum(CASE when ma.Toss_Winner=ma.Match_Winner then 1 else 0 end ) as matches_won_by_toss_winner,
sum(CASE when ma.Toss_Winner=ma.Match_Winner then 0 else 1 end ) as matches_won_by_toss_loser from 
matches ma join venue ve on 
ma.Venue_Id=ve.Venue_Id
where ma.Outcome_type in (1,3)
group by ve.Venue_Name;




-- Answer to Q.2 
/* I would suggest those players to RCB which are below or equal to the age of 27 and have taken 
either more wickets or scored nore runs in last 2 seasons. Buying young talent in the auction is very necessary because
successful teams like MI,CSK have build their team on these strategies. */

-- Firstly, we will look for young batsmen
with player_less_than_27 as (
select Player_Id,Player_Name from 
(SELECT Player_Id,Player_Name,TIMESTAMPDIFF(YEAR, DOB, '2017-01-01')AS age
FROM player) z 
where z.age<=27
),

last_season_matches as (
select ba.* from 
batsman_scored ba join matches ma 
on ba.Match_Id=ma.Match_Id  where ma.Season_Id in (9,8)
),

players_runs as (
select bl.Striker,ls.* from 
last_season_matches ls join ball_by_ball bl 
on ls.Match_Id=bl.Match_Id 
and ls.Over_Id=bl.Over_Id
and ls.Ball_Id=bl.Over_Id 
and ls.Innings_No=bl.Innings_No 
where bl.Striker in (select Player_Id from player_less_than_27)
)

select pl.Player_Name,sum(pr.runs_scored) as total_runs from 
players_runs pr join player pl 
on pr.Striker=pl.Player_Id
group by pl.Player_Name 
order by total_runs desc;

-- Now we wiil look for young bowlers
with player_less_than_27 as (
select Player_Id,Player_Name from 
(SELECT Player_Id,Player_Name,TIMESTAMPDIFF(YEAR, DOB, '2017-01-01')AS age
FROM player) z where z.age<=26
),

last_season_matches as (
select wi.* from 
wicket_taken wi join matches ma 
on wi.Match_Id=ma.Match_Id where ma.Season_Id in (9,8) and wi.Kind_Out in (1,2,4,6,7,8)
),

players_runs as (
select bl.Bowler,ls.* from 
last_season_matches ls join ball_by_ball bl 
on ls.Match_Id=bl.Match_Id 
and ls.Over_Id=bl.Over_Id
and ls.Ball_Id=bl.Over_Id 
and ls.Innings_No=bl.Innings_No 
where bl.Bowler in (select Player_Id from player_less_than_27)
)

select pl.Player_Name,count(*) as total_wickets from 
players_runs pr join player pl 
on pr.Bowler=pl.Player_Id
group by pl.Player_Name 
order by total_wickets desc;

-- Answer to Q.4 

with runs_and_matches_of_players as (
select xy.Striker,count(distinct xy.Match_Id) as total_matches,sum(xy.Runs_scored) as total_runs from 
(select bl.Match_Id,bl.Striker,ba.Runs_scored from 
ball_by_ball bl join batsman_scored ba 
on bl.Match_Id=ba.Match_Id and
bl.Over_Id=ba.Over_Id AND 
bl.Ball_Id=ba.Ball_Id and 
bl.Innings_No=ba.Innings_No ) xy 
group by xy.Striker 
),

player_average as (
select pl.Player_Name, (ru.total_runs/ru.total_matches) as average from 
player pl join runs_and_matches_of_players ru 
on pl.Player_Id=ru.Striker
),

bowler_wickets as (
select bw.Bowler,count(*) as total_wickets from 
(select wi.*,bl.Bowler from 
wicket_taken wi join ball_by_ball bl 
on wi.Match_Id=bl.Match_Id and 
wi.Over_Id=bl.Over_Id and 
wi.Ball_Id=bl.Ball_Id and 
wi.Innings_No=bl.Innings_No
where wi.Kind_Out in (1,2,4,6,7,8) ) bw 
group by bw.Bowler
),

bowler_matches as (
select Bowler, count(distinct Match_Id) as total_matches from 
ball_by_ball 
group by Bowler 
),

combine_table as ( 
select ms.Bowler,ms.total_matches,coalesce(ws.total_wickets,0) as total_wickets from 
bowler_matches ms join bowler_wickets ws 
on ms.Bowler=ws.Bowler 
),

wickets_average as (
select pl.Player_Name as Bowler_Name, (co.total_wickets/co.total_matches) as avg_wickets from  
combine_table co join player pl 
on co.Bowler=pl.Player_Id 
),


combine_runs_wickets_average as (
select pa.Player_Name,pa.average as average_runs,wa.avg_wickets from 
player_average pa join wickets_average wa 
on pa.Player_Name=wa.Bowler_Name 
)

select Player_Name,average_runs,avg_wickets from 
combine_runs_wickets_average 
where average_runs >(select avg(average) from player_average)
and avg_wickets>(select avg(avg_wickets) from wickets_average)
limit 6;


-- Answer to Q.5 
/* In this question we will check the performance 2 players, Virat Kohli and AB de Villiers 
to check whether their performance increase the morale or not. We will check their average in winning cause.*/

with rcb_won_matches_in_season_9 as (
select * from matches 
where Match_Winner=(select Team_Id from team where Team_Name='Royal Challengers Bangalore')
and Season_Id=9 and
(Team_1=(select Team_Id from team where Team_Name='Royal Challengers Bangalore')
or Team_2= (select Team_Id from team where Team_Name='Royal Challengers Bangalore') )
),

balls_vk_abd as (
select bl.* from 
ball_by_ball bl join rcb_won_matches_in_season_9 rw 
on bl.Match_Id=rw.Match_Id 
where bl.Striker in (select Player_Id from player where Player_Name in ('V Kohli','AB de Villiers') )
), 

runs as (
select bv.* ,ba.runs_scored from 
balls_vk_abd bv join batsman_scored ba 
on bv.Match_Id=ba.Match_Id and 
bv.Over_Id=ba.Over_Id and 
bv.Ball_Id=ba.Ball_Id and 
bv.Innings_No=ba.Innings_No 
),

matches_runs as (
select pl.Player_Name, count(distinct ru.Match_Id) as total_matches,sum(ru.runs_scored) as total_runs 
from runs ru join player pl 
on ru.Striker=pl.Player_Id 
group by pl.Player_Name
)

select Player_Name,(total_runs/total_matches) as average_runs_scored_in_winning_matches
from matches_runs;


-- Answer to Q.8

/* Here we are using a inforamtion to make the query short.
The info is that the home team is always written as Team_1 , you can even check 
executethat when Team_1 is MI, then ground will be Wankhede stadium. So we are 
skipping this step of finding home ground */

 with home_win as (
select Team_1,count(Match_Id) as total_home_matches,sum( CASE WHEN Match_Winner=Team_1 then 1 else 0 end ) as wins
from matches
group by Team_1 
)

select t.Team_Name,((h.wins/h.total_home_matches)*100) as home_win_percentage
from home_win h join team t 
on h.Team_1=t.Team_Id
order by home_win_percentage desc;


-- Answer to Q.9

/*  We will comsider 3-4 factors here to analyse RCB's performance.
We know that top order batting is RCB's strenght , so our factors will be more related to 
lower order and bowling.
We will consider these factors:- 
a)Total runs scored and wickets taken by RCB in previous seasons.
b) economy of RCB bowler in overs 16-20.
c) Wickets taken per inning by rcb.
d) Averages of batting position 5,6,7. */

-- a) Total runs scored and wickets taken by RCB in previous seasons.

with RCB_batting_matches as (
select ball_by_ball.* , matches.Season_Id from 
ball_by_ball join matches on ball_by_ball.Match_Id=matches.Match_Id
where ball_by_ball.Team_Batting = (select Team_Id from team where Team_name='Royal Challengers Bangalore')
),

RCB_bowling_matches as (
select ball_by_ball.* , matches.Season_Id from 
ball_by_ball join matches on ball_by_ball.Match_Id=matches.Match_Id
where ball_by_ball.Team_Bowling = (select Team_Id from team where Team_name='Royal Challengers Bangalore')
) ,

wickets_by_season as (
select rbo.Season_Id,count(*) as rcb_wickets from 
RCB_bowling_matches rbo join wicket_taken wi 
on rbo.Match_Id=wi.Match_Id and 
rbo.Over_Id=wi.Over_Id and 
rbo.Ball_Id=wi.Ball_Id and 
rbo.Innings_No=wi.Innings_No
group by rbo.Season_Id
order by rbo.Season_Id
),

runs_by_season as (
select rbm.Season_Id,sum(ba.runs_scored) as rcb_runs from 
RCB_batting_matches rbm join batsman_scored ba
on rbm.Match_Id=ba.Match_Id and  
rbm.Over_Id=ba.Over_Id and 
rbm.Ball_Id=ba.Ball_Id and 
rbm.Innings_No=ba.Innings_No 
group by rbm.Season_Id
order by rbm.Season_Id
)

select wbs.Season_Id,rbs.rcb_runs,wbs.rcb_wickets from 
wickets_by_season wbs join runs_by_season rbs 
on wbs.Season_Id=rbs.Season_Id
order by wbs.Season_Id ;


-- b) economy of RCB bowler in overs 16-20.

with over_16_20 as (
select bl.Ball_Id,ba.runs_scored 
from ball_by_ball bl join batsman_scored ba
on bl.Match_Id=ba.Match_Id
and bl.Over_Id=ba.Over_Id
and bl.Ball_Id=ba.Ball_Id
and bl.Innings_No=ba.Innings_No
where bl.Team_Bowling=(select Team_Id from team where Team_Name='Royal Challengers Bangalore')
and bl.Over_Id in (16,17,18,19,20) 
) ,

balls_runs as (
select count(Ball_Id)  as total_balls,sum(runs_scored) as runs_given 
from over_16_20
)

select (runs_given/(total_balls/6)) as economy_in_death_overs
from balls_runs;


-- c) Wickets taken per inning by rcb.

with wicket_balls as (
select wi.*  from 
wicket_taken wi join ball_by_ball bl
on wi.Match_Id=bl.Match_Id
and wi.Ball_Id=bl.Ball_Id
and wi.Over_Id=bl.Over_Id
and wi.Innings_No=bl.Innings_No
where bl.Team_Bowling=( select Team_Id from team where Team_Name='Royal Challengers Bangalore')
),

matches_wickets as (
select count(distinct Match_Id) as total_matches , count(*) as total_wickets 
from wicket_balls
)

select (total_wickets/total_matches) as wickets_taken_per_inning 
from matches_wickets;


-- d) Averages of batting position 5,6,7.

with batting_position as (
select bl.*,ba.runs_scored 
from ball_by_ball bl join batsman_scored ba
on bl.Match_Id=ba.Match_Id
and bl.Over_Id=ba.Over_Id
and bl.Ball_Id=ba.Ball_Id
and bl.Innings_No=ba.Innings_No
where bl.Team_Batting=(select Team_Id from team where Team_Name='Royal Challengers Bangalore')
and bl.Striker_Batting_Position in (5,6,7) 
),

matches_runs as (
select Striker_Batting_Position ,count(distinct Match_Id) as total_matches,sum(runs_scored) as total_runs 
from batting_position 
group by Striker_Batting_Position 
)

select Striker_Batting_Position , (total_runs/total_matches) as average 
from matches_runs ;

-- Answer to Q.11 


select Team_Id,case when 'Opponent_Team'='Delhi_Capitals' then 'Delhi_Daredevils' 
               else 'Opponent_Team' end 
               as Opponent_Team
from matches ;











































 










 
  
