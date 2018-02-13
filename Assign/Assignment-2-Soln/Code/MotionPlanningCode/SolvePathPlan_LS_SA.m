function [Path PathAPF] = SolvePathPlan_LS_SA(XYRobot, XYGoal, ...
                                XYObstacles, RadiusObstacles, FieldSize, ...
                                SAParams)

% This function solves the path planning problem using a local search 
% algorithm

% Inputs:
%
%   XYRobot:A 1x2 vector that represents the initial X, Y coordinates of 
%           the robot.
%   XYGoal: A 1x2 vector that represents the X, Y coordinates of the goal 
%   XYObstacles: A mx2 matrix that represents the X, Y coordinates of the
%                obstacles. Where m is the number of obstacles.
%   RadiusObstacles: An mx1 vector that represents the radius of the 
%                    obstacles.
%   FieldSize: A 1x2 vector that contains the field width and height.
% Outputs:
%   Path: A nx2 matrix of the locations the robot will follow along the
%         path. Where n is the number of moves along the path.
%   PathAPF: A nx2 matrix of the APF values along the path.

% Draw the soccer field
HFigure = DrawSoccerField(XYGoal, XYObstacles, RadiusObstacles, FieldSize);

% Draw the starting location of the robot
DrawRobot(HFigure, XYRobot);

% Set the current robot position and APF
CurrXYRobot = XYRobot;
CurrAPF = CalcAPF(XYRobot, XYGoal, XYObstacles, RadiusObstacles, FieldSize);

% Initialize Path and PathAPF
Path = CurrXYRobot;
PathAPF = CurrAPF;

% Initialize the best solution to the current solution
BestXYRobot = CurrXYRobot;
BestAPF = CurrAPF;

% The robot will keep going in the field until it reaches the goal or gets
% stuck at a local minimum.
while true  
    % Search the neighbourhood of the current location for a better APF
    for X = -1:1
        for Y = -1:1
            NewXYRobot = CurrXYRobot + [X Y];
            NewAPF = CalcAPF(NewXYRobot, XYGoal, XYObstacles, ...
                             RadiusObstacles, FieldSize);
           
            if NewAPF < BestAPF 
                BestXYRobot = NewXYRobot;
                BestAPF = NewAPF;
            end
        end
    end
    
    % Check if the goal is reached 
    if BestXYRobot == XYGoal 
        break
    end
    
    % Check if it's a local minimum (the current location has the best
    % APF among neighbouring locations)
    if BestXYRobot == CurrXYRobot
        
        % Use simulated annealing to escape from local minimum
        IsEscaped = false;

        % Set the current APF to the best so far
        CurrAPF = BestAPF;
        % Initialize the temparture
        Temp = SAParams.ITemp;
        while ~IsEscaped  
            for nIt = 1:SAParams.NumItsPerTemp
                % Select a random move from the neighboring location
                X = round(-1 + rand * 2); 
                Y = round(-1 + rand * 2); 
                NewXYRobot = CurrXYRobot + [X Y];
                NewAPF = CalcAPF(NewXYRobot, XYGoal, XYObstacles, ...
                             RadiusObstacles, FieldSize);

                if NewAPF < CurrAPF 
                   % Accept the solution if it's better than the current solution
                   CurrXYRobot = NewXYRobot;
                   CurrAPF = NewAPF;
                   DrawRobot(HFigure, CurrXYRobot);

                   Path = [Path; CurrXYRobot];
                   PathAPF = [PathAPF; CurrAPF];
                   
                   if CurrAPF > BestAPF
                       IsEscaped = true;
                       break;
                   end
                else
                   % Accept the solution with probability
                   APFDiff = CurrAPF - NewAPF;
                   if rand < exp(APFDiff/Temp)
                       CurrXYRobot = NewXYRobot;
                       CurrAPF = NewAPF;
                       DrawRobot(HFigure, CurrXYRobot);
    
                       Path = [Path; CurrXYRobot];
                       PathAPF = [PathAPF; CurrAPF];
                   end
                end
            end

            Temp = SAParams.Alpha * Temp;
            if Temp < SAParams.FTemp
                break;
            end
        end
    else
        % Update the path
        Path = [Path; BestXYRobot];
        PathAPF = [PathAPF; BestAPF];

        % Update the current location of the robot
        CurrXYRobot = BestXYRobot;

        % Draw the robot
        DrawRobot(HFigure, CurrXYRobot);
    end
end