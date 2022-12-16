This directory has nekrs coupled with openmc and linear feedback.


Here is how I plot and how the absolute error is calculated
(results.cvs is the file with the data from paraview)


plot (results.arc_length, results.temp,'-r', 'LineWidth',2)
xlim([0 200])
xlabel (' x (cm)')
ylabel (' Temperature (K)')
hold on
plot (results.arc_length, T(results.arc_length),'-k','LineWidth',2)

yyaxis right
plot(results.arc_length, abs( T(results.arc_length)-results.temp))
ylabel ('Difference Between Analytical and Numerical Solution')

legend ({'Cardinal (nekRS - N_x = 200)','Analytical solution','Absolute Error'},'FontSize',14)
hold off
