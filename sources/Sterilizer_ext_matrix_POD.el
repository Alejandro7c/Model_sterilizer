/*-----------------------------------------------------------------------------------------
 LIBRARY: STERILIZER
 FILE: Sterilizer_ext_matrix_POD_Santos
 CREATION DATE: 16/04/2021
 Componente esterilizador que permite escoger el producto y calcula las POD para cada un ode los productos
-----------------------------------------------------------------------------------------*/

USE MATH

FILEPATH Sterilizer_data = "@STERILIZER@/data/yout.txt"

CONST REAL TK = 273.15	
CONST REAL RL =1.0 	       				"Retort can load; between 0.5 and 1.0"

CONST INTEGER n_matrix = 12
CONST INTEGER n_distr = 10

COMPONENT Sterilizer (SET_OF(products) prod)
PORTS 
	IN vapor (saturado = TRUE) steam_in
	OUT analog_signal	y
	OUT analog_signal stage				"Stage in the sterilization process 0 stopped, 1 for heating, 2 for cooling"
	OUT analog_signal batch_in_ster			"Batch inside the sterilizator"
	IN analog_signal batch_ready			"Batch available to process"
	IN analog_signal start				"Signal to start operation 1-start, 0-stop"

DATA
	REAL Tamb   = 20 + TK		"Ambient temperature [K]"
	
	// PHE parameters
	REAL np = 45       		"Number of plates for each fluid [90 plates in total]"
	REAL Lx = 0.47     		"Plate length [m]"
	REAL Ly = 1.084    		"Plate height [m]"
	REAL Lz = 0.004    		"Plate width [m]"
	REAL Dh = 0.008 UNITS u_m "Diámetro hidráulico"

	REAL Aan = 5.11564				"Antoine equation parameter (T in K, P in bar)"
	REAL Ban = 1687.537				"Antoine equation parameter (T in K, P in bar)"
	REAL Can = -42.98					"Antoine equation parameter (T in K, P in bar)"
	REAL Cf = 0.92						"Valve parameter"
	REAL lambda = 2264.705e3 		"Water latent heat of condensation/evaporation [J/kg]"
	REAL rhow = 1000       			"Water density [kg m^{-3}]"
	REAL cpw = 4180					"Water specific heat [J kg^{-1} K^{-1}]"
	REAL Rs = R*1000/18				"Ideal gas constant - steam [J/(kg*K) = m^3 Pa/(kg*K)]"
	REAL qR = 25.0						"Mass flow in circuit R [kg/s]"
	
	REAL Tswitch = 75.0 + TK   	"When this temperature is reached in the retort, phase II ends [K]"
	REAL Tclim   = 40.0+TK  		"When this temperature is reached in the retort and..."
	REAL Tcelim  = 90.0+TK	   	"When this temperature is reached in the center of the can, cooling phase ends [K]"
	REAL Trm = 121.35+TK	      	"Retort maintenance temperature [K]; between 110 and 125"
	
//Retort variables
	REAL cp_ret = 500				"Autoclave heat capacity (From project SUPERA) [J/(kg K)]"
	REAL L_ret  = 10				"Length of the retort [m]"
	REAL R_ret  = 1				"Radius of the retort [m]"
	REAL mwR = 2000				"Retort mass data obtained from FRINSA [kg]"

	REAL e_rad  = 0.85			"Thermal emisivity (for stainless steel), in supera we used 0.94"
	REAL theta  = 5.6703e-8		"Stefan-Boltzmann constant [J/(s m^2 K^4)]"
	REAL hc = 4.494e-9 			"Convective heat transfer coefficient [W/(m^2*K)]"
	REAL nCans = 9*1600*RL		"Number of cans in the retort"
	REAL mCan  = 0.2				"Mass of the tuna in one can [kg]"
	REAL cp_can  = 588.4			"Can heat capacity (From project SUPERA) [J/(kg K)]"
	REAL Tref = 121.11+TK		"Reference temperature in lethality and color equations [K]"
	REAL zF = 10					"Lethaly equation parameter (for Clostridium botulinum) [C,K]"
	REAL Dref = 8.39e3			"TDT parameter for color temperature dependency [s]"
	REAL zC = 14.93				"TDT parameter for color temperature dependency [C,K]"
	
	REAL TA0 = 400
	REAL TB0 = 312.4
	REAL TR0 = 312.4
	REAL F00 = 0
	REAL lC0 = 2
	
	REAL trm = 1420				"Maintenance stage duration [s]"
	
DECLS

	REAL Tcool						"Cooling water in temperature 50C in cooling phase I and 20ºC in cooling phase II [K]"
	
	REAL Uw, Uw2							"Heat transfer coefficient (PHE, steam-water/water-water) [W/(m^2 K)]"
		
	REAL PA							"Pressure in the plates (circuit A) [K]"
	REAL TA							"Temperature in the plates (circuit A) [K]"
	REAL TB							"Temperature in the plates (circuit B) [K]"
	REAL qA							"Circuit A plate input flow [kg/s]"
	REAL psi
	REAL TR
	
	// PHE parameters	
	REAL UA
	REAL Ap							"Plate vertical surface [m^2]"
	REAL Aps							"Total contact area [m^2]"
	REAL Vp							"Plate volume [m^3]"
	REAL VT							"Total volume for circuit A or B [m^3]"
	REAL mwB							"Mass of water in all plates of circuit A or B [kg]"
	REAL mter

//Retort variables
	REAL m_ret						"Autoclave mass (TO BE CHECEKED) [kg]"	
	REAL qCon						"Energy loss (convection)"
	REAL qRad						"Energy loss (radiation)"
	REAL A_ret						"Effective area of the autoclave [m^2]"

	
	REAL F0				"Lethality distribution"
	REAL lC				"Color distribution"
	
//Variables for matrix operations
	INTEGER i,j
	REAL mod[n_matrix]
	REAL dmod_dt[n_matrix]

//Can variables 
	REAL qCan_1
	REAL Tce
	REAL Tup
	REAL Qcan_W		"Calor absorbido por las latas en W"	
	
// Timing variables
	DISCR REAL trm_ref

---- Heat coefficient calculations
-- Vapor quality 
	REAL x_av_A UNITS no_units "cantidad de vapor en A"
	
	 	 -- Cálculo de los coeficientes de película en B
	     -- Viscosidad del agua en B
-- Viscosidad
	REAL mu_B UNITS "Pa*s" "Viscosidad en el canal B"
	REAL mu_A UNITS "Pa*s" "Viscosidad en el canal B"

-- Parametros adimensionales
	REAL Re_B UNITS no_units " Número de Reynolds en B"
	REAL Re_A UNITS no_units " Número de Reynolds en A eq"
	REAL Pr_B UNITS no_units "Número de Prandtl en B"
	REAL Pr_A UNITS no_units "Número de Prandtl en A"
	REAL Nu_B UNITS no_units " Número de Nusselt "
	REAL Nu_A UNITS no_units " Número de Nusselt "
--	REAL Bo_A UNITS no_units " Número de Boiling "
-- Coeficientes de película
	REAL h_B UNITS u_MW_m2K  "Coeficiente de película en B"
	REAL h_A UNITS u_MW_m2K  "Coeficiente de película en A"
-- Conductividad
	REAL k_B UNITS "W/m/K" "Conductividad térmica"
	REAL k_A UNITS "W/m/K" "Conductividad térmica"

	REAL c_LA UNITS u_kmol_m3 "Densidad molar del líquido"
	REAL c_VA UNITS u_kmol_m3 "Densidad molar del vapor"
	REAL h_LA UNITS u_MJ_kmol "Entalpía molar del líquido en circuito A"
	REAL h_VA UNITS u_MJ_kmol "Entalpía molar del vapor en circuito A"	
	
-- Conductividad dermica del acero
	CONST REAL k_acero = 16.3 UNITS "W/(K*m)" "Conductividad térmica del acero inoxidable AISI 304"

-- Calor intercambiado entre circuitos
	REAL Q UNITS u_MW "Calor intercambiado entre placas"

   REAL x_A[Comp] UNITS no_units "Fracciones molares en líquido circuito A" 	
   REAL y_A[Comp] UNITS no_units "Fracciones molares en vapor circuito A" 	

INIT
// Initial values (test for FMU)

	TA = TA0
	TB = TB0
	TR = TB0
		F0 = F00
		lC = lC0

//Values in stage.signal 1 (heating)

	mod[1] = 1.52628452256236
	mod[2] = 0.0150186265758665
	mod[3] = 9.49536662201572e-06
	mod[4] = 0.00122697153252045
	mod[5] = -0.000775274062372256
	mod[6] = -3.44684431168030e-06
	mod[7] = 0.000196290612514333
	mod[8] = 6.04813836914044e-05
	mod[9] = 9.17723580323715e-08
	mod[10] = 2.44815032361331e-05
	mod[11] = -2.34765781401691e-05
	mod[12] = 1.27664546850648e-08

DISCRETE

	
CONTINUOUS
		qCan_1=FCM*Qcan_W		
		SEQUENTIAL
		   IF (setofCmp(prod,RO80_oil)) THEN
			latas_POD_RO80_oil(mod, TR, dmod_dt, qCan_1, Tce, Tup)
			END IF
			IF (setofCmp(prod,RO80_water)) THEN
			latas_POD_RO80_water(mod, TR, dmod_dt, qCan_1, Tce, Tup)
			END IF
		   IF (setofCmp(prod,RO200_oil)) THEN
			latas_POD_RO200_oil(mod, TR, dmod_dt, qCan_1, Tce, Tup)
			END IF
			IF (setofCmp(prod,RO200_water)) THEN
			latas_POD_RO200_water(mod, TR, dmod_dt, qCan_1, Tce, Tup)
			END IF
		END SEQUENTIAL

		EXPAND(j IN 1,n_matrix) 		mod[j]' = dmod_dt[j]
	
// HEat exchanger dimmensions	
	Ap  = Lx*Ly    //plate vertical surface [m^2]
	Aps = Ap*np    //Total contact area [m^2]
	Vp  = Lx*Ly*Lz //plate volume [m^3]
	VT  = np*Vp    //Total volume for circuit A or B [m^3]
	mwB = VT*rhow  //mass of water in all plates of circuit A or B [kg]

	UA  = Uw*Aps    // Heat transfer times contact area [W/K] 	
		
// ============================ ODEs (PHE) ================================
// Pressure expressions
	PA =  (10.0**(Aan - Ban/(Can + TA))*101325.0)    // Steam pressure after the valve [Pa]
	steam_in.P = PA / 100000

	qA = ZONE (stage.signal ==1 ) steam_in.W
		  ZONE (stage.signal ==2 ) 18.
		  OTHERS 0.
// Condensation flux (equal to the energy transmitted to the cold fluid)
	Q = UA*(TA-TB)
	psi  = UA*(TA-TB)/lambda
// Energy balance in plates with steam

	mter = PA*VT/(Rs*TA)*(log(10.0)*Ban/(TA+Can)**2.0 - 1.0/TA)
	TA' = ZONE( stage.signal == 1)	1.0/mter*(qA - psi)
			ZONE (stage.signal == 2)   1.0/(mwB*cpw)*(qA*cpw*(Tcool-TA) + UA*(TB-TA))
			OTHERS 0

//Energy balance in plates with liquid
	TB' = ZONE( stage.signal == 1)  1.0/(mwB*cpw)*(qR*cpw*(TR-TB) + UA*(TA-TB))
			ZONE (stage.signal == 2)  1.0/(mwB*cpw)*(qR*cpw*(TR-TB) + UA*(TA-TB))		
			OTHERS 0
			// estas dos ecuaciones son iguales, en su modelo no, porque
			// usan la variable mwp en vez de mwB, pero es la misma variable.
	
	Tcool = ZONE (TR<=Tswitch AND stage.signal>1) 20 + TK
				OTHERS 50 + TK
				
	Uw2 = ZONE( stage.signal == 1)  2987.68
      	ZONE (stage.signal == 2)  4000.
		OTHERS 0
	
// ================== Retort equations ====================================
	m_ret  = 2.846e6/cp_ret					//Autoclave mass (TO BE CHECEKED) [kg]
	A_ret  = 2*MATH.PI*R_ret*L_ret		//Effective area of the autoclave [m^2]
// Heat absorbed
	qCon = hc*A_ret*(TR-Tamb)              // Energy loss (convection)
	qRad = theta*e_rad*A_ret*(TR**4.0-Tamb**4.0) // Energy loss (radiation)
// Energy balance in the retort
	TR' = 1.0/(mwR*cpw+m_ret*cp_ret)*(qR*cpw*(TB-TR) - (qCon+qRad+SUM(i IN 1,n_distr; qCan_1)/n_distr))
	
// ================== Retort equations ====================================
	y.signal  = TR
	
//ODE lethality, we divide by 60 to give the lethality value in minutes
	F0' = ZONE( stage.signal == 1 OR stage.signal == 2)  10.0**((Tce-Tref)/zF)/60.0
	OTHERS 0
	
// ODE Color
	lC' = ZONE( stage.signal == 1 OR stage.signal == 2) -1.0/Dref*10.0**((Tup-Tref)/zC)
	OTHERS 0

-----------------------------------------------------------------------------------------
	EXPAND( i IN Comp)   x_A[i] = 1
	EXPAND( i IN Comp)   y_A[i] = 1
	
	c_VA = GasIdeal(PA/10**6, TA)
	c_LA = DensidadLiquido (agua,TA,x_A)/18
	h_VA = EntalpiaGasIdeal(TA,y_A)
  	h_LA = EntalpiaLiquidoIdeal (agua, TA, x_A) 
	  
	  
	mu_B = exp(-3.7188+578.919/(-137.546+TB))/10**3
		  
-- Reinolds en B
	Re_B = qR*Dh/mu_B
		  
-- Prandtl en B
	Pr_B = cpw*mu_B/k_B
	k_B = 0.56112+0.00193*(TB-273.015)-0.00132*(TB)**3+9.415e-6*TB**4-2.5479e-8**TB**5
	     
-- Correlación de Thonon para beta 30º
	Nu_B = 0.2946*Re_B**0.7*Pr_B**(1/3)
	h_B = max(Nu_B*k_B/Dh,0.001)
		  
-- Cálculo de los coeficientes de película en A
	-- Viscosidad del agua en A
	mu_A = exp(-3.7188+578.919/(-137.546+TA))/10**3
		  
-- Reinolds(eq) en A
	--*/*/*/*/*/Re_A = qA*Dh/mu_A
	Re_A = qA*((1-x_av_A)+x_av_A*(c_LA/c_VA)**0.5)*Dh/mu_A
		  
-- Vapor quality
	x_av_A = 0.--M_VA/M_TA
		  
-- Prandtl en A (l)
	Pr_A = cpw*mu_A/k_A
	k_A = 0.56112+0.00193*(TA-273.015)-0.00132*(TA)**3+9.415e-6*TA**4-2.5479e-8**TA**5
		  
-- Nusset en A
	-- Wang y Zhao 1993 condensate correlation
	Nu_A = 0.00115*(Re_A)**0.983*Pr_A**0.33*(c_LA/c_VA)**0.248
	h_A = max(Nu_A*k_A/Dh,0.001)
			
-- Coeficiente de trasferencia de calor
	Uw  =1/(1/h_A + 1/h_B + Lz/k_acero) --*FCM

END COMPONENT

COMPONENT Unit_Sterilizer (SET_OF(products) prod)
PORTS 
	IN vapor (saturado=TRUE) steam_in
	OUT analog_signal stage				"Stage in the sterilization process 0 stopped, 1 for heating, 2 for cooling"
	OUT analog_signal batch_in_ster			"Batch inside the sterilizator"
	IN analog_signal batch_ready			"Batch available to process"
	IN analog_signal start				"Signal to start operation 1-start, 0-stop"
DATA

TOPOLOGY
	Sterilizer			(prod=prod)					st1

	Valvula_v	(saturado=TRUE)	v_st1 (Cf = 0.92,Cv = 11)

   CONNECT steam_in TO v_st1.f_in
	CONNECT v_st1.f_out TO st1.steam_in


INIT
		st1.TA = 178+273
      st1.TB = 312.4
      st1.TR = 312.4
		st1.lC = 2
		st1.F0 = 0
      st1.PA = 200000

DISCRETE

CONTINUOUS
   steam_in.P = 9.8

	stage.signal = st1.stage.signal
	start.signal = st1.start.signal
	batch_in_ster.signal = st1.batch_in_ster.signal
	batch_ready.signal = st1.batch_ready.signal
	
	steam_in.T = temp_sat_w(steam_in.P)
END COMPONENT
