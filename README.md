# ipsc-whatif
scripts for getting matchresults in IPSC from shootand scoreit and create a DB in sqlite to then analyse "whatif". Whatif i was a second faster

# IPSC is a shooting competition where every match consists of stages. Every stage has a certain nr of points, 
and the targets generate points by being hit in A,C or D zones. The time it takes to shoot is then used to divide the points on the 
targets. The shooter with the highest "factor" (points divided by time) then wins that stage. The other shooters get
scores depending on the percentage of the first shooter achivment. If shooter A wins a stage by scoring 50 points on 5seconds
He gets a factor of 10. If shooter B manages the only 25 points due to some misses but also on 5 seconds he gets a factor of 25/5 = 5

Shooter A then wins that stage and gets 100%. Shooter B had a factor that is half, and so gets 50% on that stage.

After a match there is always a discussion among shooters. "What if" i dident have that miss.. WHatif my time was half a second faster
etc etc etc.

This is a set of scripts that take scores from SSI (Shoot and scoreit) website with all the matchresults. Poulates a database
and you can then from that database edit a shooters score and see the result.

My ambition is to be able to create a set of tools to analyse a shooters performance over time.
