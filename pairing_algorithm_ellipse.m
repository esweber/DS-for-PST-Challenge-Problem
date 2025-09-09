%   All data must be converted as follows:
%   1 tenths of a degree Course = (pi/1800) radians
%   1 deg Latitude = 69.172 miles
%   1 deg Longitude = 69.172*cos(Lat) miles
%   Time in hours, starting from 0.
%   1 tenths of a knot = 0.115078 mph
%   Time must be in increasing order.

%   Reading the size of the data set.
DataSize = size(Time,1);


%   Defining the distance matrix, a strictly upper triangular matrix.
%   Parameters:
A = 0.3;
B = 0.7;
C = 1;
D = 5;
E = 15;
F = 0.4;
G = 4*max(Speed);
DistMatrix = zeros(DataSize,DataSize);
for m = 1:(DataSize - 1)
    for n = (m + 1):DataSize
        LA = Latitude(n) - Latitude(m);
        LO = Longitude(n) - Longitude(m);
        TI = Time(n) - Time(m);
        SP = Speed(n) - Speed(m);
        CO = Course(n) - Course(m);
        L1 = (LO - Speed(m)*TI*sin(Course(m)));
        L2 = (LA - Speed(m)*TI*cos(Course(m)));
        DistMatrix(m,n) = A*sqrt(LO^2 + LA^2) + B*sqrt(L1^2 + L2^2) + C*abs(TI);
        if DistMatrix(m,n) > D
            DistMatrix(m,n) = 0;
        end
        if Speed(m)*sqrt(1 - cos(CO)) > E
            DistMatrix(m,n)=0;
        end
        if abs(TI) > F
            DistMatrix(m,n) = 0;
        end
        if TI > 0 && sqrt(LA^2 + LO^2)/TI > G
            DistMatrix(m,n) = 0;
        end
    end
end

%   Assign each data point {z_n} a track ID as follows:
%   1. Calculate the minimum nonzero distance, MinDist
%   2. Find A = {(z_m,z_n)} for which DistMatrix(z_m,z_n) = MinDist
%   3. Let M = max{m : (z_m,z_n) in A}, i.e. the index of the latest point
%   4. Let N = min{n : (z_M,z_n) in A}, i.e. the closest correlated point
%   5. Identify z_M and z_N as belonging to the same track
%   6. Repeat steps 1. through 5. for the remaining data
OldTrackIDs = zeros(DataSize,1);
MaxDist = max(DistMatrix(:));
k = 0;
while MaxDist > 0
    Indices = DistMatrix > 0;
    MinDist = min(DistMatrix(Indices));
    for m = 1:(DataSize - 1)
        for n = (DataSize - m + 1):DataSize
            if DistMatrix(DataSize - m,n) == MinDist
                M = DataSize - m;
                N = n;
                break
            end
        end
    end
    if OldTrackIDs(M) ~= 0 || OldTrackIDs(N) ~= 0
        if OldTrackIDs(M) ~= 0 && OldTrackIDs(N) == 0
            OldTrackIDs(N) = OldTrackIDs(M);
        elseif OldTrackIDs(M) == 0 && OldTrackIDs(N) ~= 0
            OldTrackIDs(M) = OldTrackIDs(N);
        else
            Min = min(OldTrackIDs(M),OldTrackIDs(N));
            Max = max(OldTrackIDs(M),OldTrackIDs(N));
            for m = 1:DataSize
                if OldTrackIDs(m) == Max
                    OldTrackIDs(m) = Min;
                end
            end
        end
    else
        k = k + 1;
        OldTrackIDs(M) = k;
        OldTrackIDs(N) = k;
    end
    for m = 1:N
        DistMatrix(m,N) = 0;
    end
    for n = M:DataSize
        DistMatrix(M,n) = 0;
    end
    MaxDist = max(DistMatrix(:));
end

TrackIDs = zeros(DataSize,1);
u = unique(OldTrackIDs);
NumberOfTracks = size(u,1);
for m = 1:NumberOfTracks
    j = u(m);
    for n = 1:DataSize
        if OldTrackIDs(n) == j
            TrackIDs(n) = m;
        end
    end
end

TrackIndices = zeros(DataSize,NumberOfTracks);
TrackSize = zeros(NumberOfTracks,1);
for m = 1:DataSize
    TrackSize(TrackIDs(m)) = TrackSize(TrackIDs(m)) + 1;
    TrackIndices(TrackSize(TrackIDs(m)),TrackIDs(m)) = m;
end
TrackData = zeros(DataSize,3*NumberOfTracks);
for m = 1:NumberOfTracks
    for n = 1:TrackSize(m)
        TrackData(n,3*m) = Longitude(TrackIndices(n,m));
        TrackData(n,3*m - 1) = Latitude(TrackIndices(n,m));
        TrackData(n,3*m - 2) = Time(TrackIndices(n,m));
    end
end

fprintf('The number of tracks is % d \n', NumberOfTracks);

figure(1)
hold on
for m = 1:NumberOfTracks
    scatter3(TrackData(1:TrackSize(m),3*m-2),TrackData(1:TrackSize(m),3*m-1),TrackData(1:TrackSize(m),3*m),'filled')
end
hold off

TrackLength = zeros(NumberOfTracks,1);
for m = 1:NumberOfTracks
    if TrackSize(m) == 1
        TrackLength(m) = 0;
    else
        for n = 1:(TrackSize(m) - 1)
            L1 = TrackData(n + 1,3*m - 1) - TrackData(n,3*m - 1);
            L2 = TrackData(n + 1,3*m) - TrackData(n,3*m);
            TrackLength(m) = TrackLength(m) + sqrt(L1^2 + L2^2);
        end
    end
end

TotalLength = 0;
for m = 1:NumberOfTracks
    TotalLength = TrackLength(m) + TotalLength;
end

fprintf('The total length of all of the tracks is % d \n', TotalLength);

figure(2)
plot(TrackLength)