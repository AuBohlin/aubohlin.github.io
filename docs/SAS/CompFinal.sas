data premades;
 input team_id $ teammate1 $ teammate2 $;
datalines;
1 P1 P22
2 P2 P34
;

data lobbies;
 input lobby $ target_kd;
datalines;
A 4.25
B 5.0
C 5.75
;

proc optmodel;
/* Load in the Player Data */
set <str> PLAYERS; /* declare Player index set with P# as index*/
num player_kd{PLAYERS}; /* declare player_kd as a column*/
read data work.player_data into PLAYERS=[players] player_kd;

/* Load in the Lobby Data */
set <str> LOBBIES;
num target_kd{LOBBIES};
read data lobbies into LOBBIES = [Lobby] target_kd;

/* Load in the premade teams  */
set <str> PREMADES;
str teammate1{PREMADES};
str teammate2{PREMADES};
read data premades into PREMADES = [team_id] teammate1 teammate2;

/* 3D group matrix to show players combos and lobby */
var groups{i in players, j in players, a in lobbies} binary;

/* Optfunction without presolve */
minimize z = sum{i in players, j in players, a in lobbies: i<j} 
				groups[i,j,a]*(target_kd[a]-(player_kd[i]+player_kd[j]))^2;

/* Constraints */
/* Force the teams to be fixed */
con teams {x in PREMADES}:
	sum{a in lobbies} groups[<teammate1[x]>,<teammate2[x]>,a] = 1;

/* Each slice of the 3D assignments have to be = 0 */
con twopalyerteamperpalyercolumn {j in players}: /* alpha */
	sum {i in players, a in lobbies} groups[<i>, j, a] = 1;
con twoplayerteamperpalyerrows {i in players}: /* beta */
	sum {j in players, a in lobbies} groups[i, <j>, a] = 1;
con cantbeonateamofone {i in players, a in lobbies}: /* delta*/
	groups[i,i,a] = 0;


/* Both players on same team and in same lobby*/
con sameteamlobby {i in players, j in players, a in lobbies: i < j}: /* epsilon */ 
	groups[i,j,a] = groups[j,i,a];

/* Lobbys have a min cap of 48 and max of 52 */
con lobbymin {a in lobbies}:  /* gamma */
	sum {i in players, j in players:i<j} groups[i,j,<a>] >=(48);
con lobbymax {a in lobbies}: /* gamma */
	sum {i in players, j in players:i<j} groups[i,j,<a>] <=(52);
solve;

/* Creates the dataframe with the solution */
create data solution from [player1=i player2=j lobby=a]={i in PLAYERS, j in Players, a in lobbies:((groups[i,j,a].sol = 1) & i<j)} 
	TeamKD=(player_kd[i]+player_kd[j]);

file log;
put "Team Members: Austin Bohlin, Nilabh Chaturvedy";
put "Date and Time: %sysfunc(date(),date9.) %sysfunc(time(),timeampm8.)";
quit;