% Simple time-series script for CNAPS
%
% Joseph B. Zambon, Ph.D.
% jbzambon@ncsu.edu
% 1 February 2017

clear all; close all;

% Input lat/lon coords for area of interest (e.g. RDU Airport)
loc_coord = [35.8776389, -78.7874722];  % RDU Airport
variable_of_interest = 'T_2m';  %2m temperature

% Load nctoolbox into path
run /home/jbzambon/MatlabCodes/nctoolbox/setup_nctoolbox.m

%Connect to OPeNDAP Server
nc = ncgeodataset('http://oceanus.meas.ncsu.edu:8080/thredds/dodsC/fmrc/useast_coawst_wrf/COAWST-WRF_Forecast_Model_Run_Collection_best.ncd');

% Get grid lat/lon
lat = nc{'lat'}(:);
lon = nc{'lon'}(:);

% Find nearest model grid point (ii, jj), simple Pythagorean reduction from coords
dis=sqrt((lon-loc_coord(2)).^2+(lat-loc_coord(1)).^2);
index=find(dis==min(dis(:)));
[m,n]=size(lon);
ii=floor((index-1)/m)+1;
jj=rem(index,m);

% Print out model lat/lon from ii,jj points and calculate distance
% Coarser grids = larger possible distance.  In that case, you might want to use a
% spatial interpolation between nearby grid points to get better results.
% Don't reinvent the wheel... haversine.m works well here.
lat_ij = nc{'lat'}(jj,ii);
lon_ij = nc{'lon'}(jj,ii);
dist_km = haversine([loc_coord(1) loc_coord(2)],[lat_ij, lon_ij]);
disp(['The distance between grid point and requested point is ' num2str(dist_km) 'km'])

% Define bounds for your timeseries (you don't want to go back to the beginning of time here...)
model_time = nc{'time'}(:,jj,ii);  %spits out hours since 2016-9-20
reference_time = datenum('20-Sept-2016');  %Define reference time.  Check metadata, this varies by dataset
actual_time = model_time/24 + reference_time;  %Add to reference to get non-model time.  Divide by 24 as datenum works in days, not hours.
% You now have the model date/time, so define your bounds of interest
start_time = datenum('25-Dec-2016'); % Have a Merry Christmas
end_time = datenum('1-Jan-2017');    % ... and a Happy New Year

% get time indices of interest
time_inx = find(actual_time>= start_time & actual_time <= end_time);

% Now you know grid points.
% You know the distance between them and where you're looking is not too large.
% You know the indices of the time you're interested in.
% You can now download a specific variable at the specific location at the specific time.
% This is much more efficient than downloading the entire ~300GB dataset.

timeseries_data = nc{variable_of_interest}(time_inx(1):time_inx(end),jj,ii);
% You now have the data.  Plot it!

set(figure(1),'Position',[0 30 1500 1000],'Visible','on','Renderer','Zbuffer')
plot(actual_time(time_inx(1):time_inx(end)),timeseries_data(:),'k')
axis([actual_time(time_inx(1)) actual_time(time_inx(end)) min(timeseries_data)-0.5 max(timeseries_data)+0.5])
datetick('x','dd-mmm-yyyy')
ylabel('Temperature \circC')
xlabel('Model Day')
title('CNAPS 2m Temperature','FontSize',18)
screen2png('temp2m.png')

