# lua-golf-battle
Golf-based minigame developed on LUA.

# PREVIEW

- Gamemode 1 (normal run): https://youtu.be/zAl-Oms9Nok
- Gamemode 2 (death run): https://youtu.be/aZSx_jIOq7M

# DEVELOPMENT DATA:

1. This Golf minigame was created based on this android game: https://youtu.be/TA1tkJ0Y8R8 
2. This project was developed for an online multiplayuer game called MTA which is based on GTA San Andreas. Further, it was developecd for a server that I will not mention with no remunetarion. My main goal was improving my logical and programming knowledge on LUA. 
3. Time taken: 2 weeks.
4. Fully developed from scratch by Andrés Henao Alzate.
5. No frameworks.
6. Hosts is short for "people hosting the event".
7. Handles both CLIENT and SERVER.

# ABOUT:

There are tooltips for almost everything since some people fail to understand the simplest thing.
Custom sounds.
Hosts can use custom maps and build custom courses as they choose.
Hosts can place as many holes as they want. Every hole counts as a round. 2 holes = 2 rounds.
If two players reached the last hole and both of them have the same score, a untie round will be played (minute 3:04 of video #2). In this round, the closest player to the hole (flag) is picked as the winner.
Custom objects are created for the untie round's map (minute 3:04 of video #2).
When the death run game mode is running and someone fails to reach the hole on time, they're killed.
When the normal game mode is running and someone fails to reach the active hole, they're given 10 points or they're killed depending on the /golf elim setting.
When the normal game mode is running and someone reaches the last hole, everyone else is killed when the expiration time is over.
Detects players in the water and automatically warps them back to their previous position to prevent the host's annoyance.
If the expiration time of the death run game mode is over or the overall event's max time of the normal game mode is over and no one has reached the last hole, then no one is picked as the winner.
Even if you have the lowest score but you fail to reach the last hole, you will not win.
Even if you fail to reach one or many holes, you'll still have the chance to win as long as your score is the lowest somehow and reach the last hole.
Players can warp back to the spawn point (object with ID 2898 on round == 1, else the previous hole) by using LSHIFT.
Players can save their current position by using ARROW DOWN.
Players can spectate their opponents with ARROW LEFT/RIGHT once they arrive at the hole.

# COMMANDS:

/start CDgolfBattle
/golf load - Detects the valid golf holes and the spawn point.
/golf time <minutes> - OPTIONAL. This is the overall duration of the event from beginning to end. If no one has reached the last hole once it's over, then no one will be picked as the winner. The default value is 3 minutes.
/golf exp <seconds> - OPTIONAL. This is the expiration time that runs in 2 cases: 1. when a round is playing and someone arrives first at the hole; 2. when the death run game mode is enabled, hence, this would be the time that the participants have available to reach the hole on time. The default value is 20 seconds.
/golf elim <1 / 2> - OPTIONAL. 1 = No one is killed after each round (default); 2 = The last participant on the scoreboard is killed after each round.
/golf start <1 / 2> - OPTIONAL. 1 = Normal game mode with no expiration time (default when no arg is provided); 2 = Death run in which people play against time. If they fail to reach the hole, they die.
/golf stop - Stops the event.
/golf unload - Unloads the detected objects.
