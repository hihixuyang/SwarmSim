classdef world
    %WORLD simulated environment with multiple robots and obstacles
    
    properties
        env        % multi robot environment object
        numRobots  % number of robot in the system
        numSensors % number of sensors equiped on each robot
        sensorRange% maximum range of sensing
        poses      % current poses of each robot
        sensors    % sensor information of each robot
        detectors  % robot detector of each robot
    end
    
    methods
        function obj = world(swarmInfo)
            %WORLD constructor
            numRobots = swarmInfo.numRobots;
            showTraj = swarmInfo.showTraj;
            poses = swarmInfo.poses;
            obj.numRobots = numRobots;
            obj.env = MultiRobotEnv(obj.numRobots);
            obj.env.showTrajectory = showTraj;
            obj.env.robotRadius = 0.25;
            obj.env.mapName = 'map';
            obj.sensors = cell(1,obj.numRobots);
            obj.detectors = cell(1,obj.numRobots);
            for i = 1:obj.numRobots
                robotInfo = swarmInfo.infos{i};
                % associate range finders for each robot
                lidar = LidarSensor;
                lidar.scanAngles = linspace(-pi,pi,robotInfo.numSensors);
                lidar.maxRange = robotInfo.sensorRange;
                attachLidarSensor(obj.env,i,lidar); % associate lidar with map
                obj.sensors{i} = lidar;
                % associate robot detector of each robot
                detector = RobotDetector(obj.env,i);
                detector.sensorOffset = [0 0];
                detector.sensorAngle = 0;
                detector.fieldOfView = 2*pi;  % full range robot detection
                detector.maxRange = robotInfo.sensorRange;
                detector.maxDetections = obj.numRobots-1; % maximum number of detections
                obj.detectors{i} = detector;
            end
            
            obj.poses = poses; % initial poses
        end
        
        function obj = update_poses(obj,new_poses)
            % return the current poses
            obj.poses = new_poses;
        end
        
        function poses = get_poses(obj)
            % update current poses
            poses = obj.poses;
        end
        
        function ranges = readSensors(obj)
            % read sensors at current poses
            ranges = cell(1,obj.numRobots); % empty sensor readings
            for i = 1:obj.numRobots
                lidar = obj.sensors{i};
                scans = lidar(obj.poses(:,i));
                ranges{i} = scans;
            end
        end
        
        function detections = readDetections(obj)
            % read robot detection result [numDetections, 3] [range angle idx]
            detections = cell(1,obj.numRobots);
            for i = 1:obj.numRobots
                detector = obj.detectors{i};
                detection = step(detector);
                detections{i} = detection;
            end
        end
        
        function visualize(obj,ranges)
            % visualize sensor readings at current poses
            obj.env(1:obj.numRobots,obj.poses,ranges);
        end
    end
end

