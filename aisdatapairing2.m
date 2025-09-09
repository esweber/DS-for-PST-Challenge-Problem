[rows,columns] = size(Time);

Dist = zeros(rows,rows);

for m = 1:(rows - 1)
    for n = (m + 1):rows
        LA = Latitude(m) - Latitude(n);
        LO = Longitude(m) - Longitude(n);
        TI = Time(m) - Time(n);
        SP = Speed(m) - Speed(n);
        CO = Course(m)-Course(n);
        Dist(m,n) = sqrt(LO^2 + LA^2)+0.5*sqrt((LO-Speed(m)*TI*sin(Course(m)))^2+(LA-Speed(m)*TI*cos(Course(m)))^2)+abs(TI);
        if Dist(m,n) > 5
            Dist(m,n) = 0;
        end
        if Speed(m)*sqrt(1-cos(CO))>15
            Dist(m,n)=0;
        end
        if abs(TI) > 0.5
            Dist(m,n) = 0;
        end
    end
end

Components = zeros(rows,1);
MaxDist = max(Dist(:));
k = 0;
while MaxDist > 0
    MinDist = -1;
    M = 0;
    N = 0;
    for m = 1:(rows - 1)
        for n = (m + 1):rows
            if Dist(m,n) > 0
                if MinDist == -1
                    MinDist = Dist(m,n);
                    M = m;
                    N = n;
                elseif Dist(m,n) < MinDist
                    MinDist = Dist(m,n);
                    M = m;
                    N = n;
                end
            end
        end
    end
    for m = 1:N
        Dist(m,N) = 0;
    end
    for n = M:rows
        Dist(M,n) = 0;
    end
    MaxDist = max(Dist(:));
    if Components (M) ~= 0 || Components (N) ~= 0
        if Components (M) ~= 0 && Components(N) == 0
            Components(N) = Components(M);
        elseif Components(M) == 0 && Components (N) ~= 0
            Components(M) = Components(N);
        else
            Min = min(Components(M),Components(N));
            Max = max(Components(M),Components(N));
            for m = 1:rows
                if Components(m) == Max
                    Components(m) = Min;
                end
            end
        end
    else
        k = k + 1;
        Components(M) = k;
        Components(N) = k;
    end
end

Comp = zeros(rows,rows);
CompSize = zeros(rows,1);
CompNumber = 0;
MaxIndex = 1;

while MaxIndex > 0
    MaxIndex = max(Components(:));
    CompNumber = CompNumber + 1;
    j = 0;
    for m = 1:rows
        if Components(m) == MaxIndex
            CompSize(CompNumber) = CompSize(CompNumber) + 1;
            Components(m) = 0;
            j = j + 1;
            Comp(j,CompNumber) = m;
        end
    end
end

Connected = zeros(rows,3*CompNumber);
for m = 1:CompNumber
    for n = 1:CompSize(m)
        Connected(n,3*m) = Longitude(Comp(n,m));
        Connected(n,3*m - 1) = Latitude(Comp(n,m));
        Connected(n,3*m - 2) = Time(Comp(n,m));
    end
end

fprintf('The number of connected components is % d \n', CompNumber-1);

figure(1)
hold on
for m = 1:CompNumber-1
    scatter3(Connected(1:CompSize(m),3*m-2),Connected(1:CompSize(m),3*m-1),Connected(1:CompSize(m),3*m),'filled')
end
hold off


%scatter plot of the ground truth
%figure(2)
%scatter(Time, Latitude,30,VID-100000,'filled')


for m = 1:(CompNumber-1)
    for n = 1:CompSize(m)
        Components(Comp(n,m)) = m;
    end
end