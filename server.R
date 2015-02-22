library(shiny)
library(UsingR)
batting_copy <<- batting
# team statistics from http://mlb.mlb.com/ 
team_stats <<- data.frame(matrix(c(
  'NYA', 'BOS', 'CHA', 'ANA', 'TEX', 'ARI', 'SEA', 'TOR', 'OAK', 'SLN', 'SFN','COL','MIN', 'HOU','CLE','KCA','MON','LAN','PHI','CIN','ATL','CHN','FLO','NYN','TBA','BAL','SDN','PIT','MIL','DET',
  897,859,856,851,843,819,814,813,800,787,783,778,768,749,739,737,735,713,710,709,708,706,699,690,673,667,662,641,627,575,
  103, 93,81,99,72,98,93,78,103,97,95,73,94,84,74,62,83,92,80,78,101,67,79,75,55,67,66,72,56,55
), ncol=3))
colnames(batting_copy) <- c('playerID', 'yearID', 'stintID', 'teamID', 'lgID', 'Games','AtBats','Runs',
                       'Hits','Doubles','Triples','HomeRuns','RBIs','StolenBases','CaughtStealing', 
                       'BasesOnBalls','StrikeOuts','IntentionalBasesOnBalls', 
                       'HitByPitch', 'SacrificeHits', 'SacrificeFlies', 'GroundIntoDoublePlays')
colnames(team_stats) <- c('team', 'Runs', 'Wins')
team_stats$Runs <- as.numeric(as.character(team_stats$Runs))
team_stats$Wins <- as.numeric(as.character(team_stats$Wins))

batting_copy$TotalBases <- batting_copy$Hits + batting_copy$Doubles + batting_copy$Triples*2 + batting_copy$HomeRuns*3
batting_copy$RunsCreated <- ((batting_copy$Hits + batting_copy$BasesOnBalls) * batting_copy$TotalBases)/(batting_copy$AtBats+batting_copy$BasesOnBalls)
batting_copy$RunsCreatedWithStolenBases <- ((batting_copy$Hits + batting_copy$BasesOnBalls - batting_copy$CaughtStealing) * (batting_copy$TotalBases + .55*batting_copy$StolenBases))/(batting_copy$AtBats+batting_copy$BasesOnBalls)
batting_copy$RunsCreatedAdvanced <- ((batting_copy$Hits+batting_copy$BasesOnBalls-batting_copy$CaughtStealing+batting_copy$HitByPitch-batting_copy$GroundIntoDoublePlays)*
                               (batting_copy$TotalBases+.26*(batting_copy$BasesOnBalls-batting_copy$IntentionalBasesOnBalls+batting_copy$HitByPitch) 
                               + .52*(batting_copy$SacrificeHits+batting_copy$SacrificeFlies+batting_copy$StolenBases)))/
                              (batting_copy$AtBats+batting_copy$BasesOnBalls+batting_copy$HitByPitch+batting_copy$SacrificeHits+batting_copy$SacrificeFlies)
batting_copy$RunsCreated2002 <- batting_copy$Hits + batting_copy$BasesOnBalls - batting_copy$CaughtStealing + batting_copy$HitByPitch - batting_copy$GroundIntoDoublePlay


shinyServer(function(input, output) {
  createModel <- function(predictor="Hits", prediction="Runs") {
    teamID <- unique(batting_copy$teamID)
    team_predictor <- aggregate(batting_copy[predictor],list(batting_copy$teamID), sum)
    colnames(team_predictor) <- c('team', 'predictor')
    result <- merge(team_predictor, team_stats)
    result$predictor <- as.numeric(result$predictor)
    result$Runs <- as.double(result$Runs)
    result$Wins <- as.double(result$Wins)
    model <- lm(as.formula(paste(prediction, "~", "predictor")), result)
  }
    
# use the sum of the input values for teams to predict the total team output value 
  output$predictor <- renderPrint({input$predictor})
  output$prediction <- renderPrint({input$prediction})
  model <- reactive({createModel(input$predictor)})
  output$diagnostics <- renderPlot({
      layout(matrix(c(1,2,3,4),2,2)) # optional 4 graphs/page 
      plot(model())
  })
                               
  output$summary <- renderPrint({summary(model())})
  output$anova <- renderPrint({anova(model())})
})
