/*-----------------------------------------------------------------------------------------
 LIBRARY: STERILIZER
 FILE: Valvula_ON_OFF
 CREATION DATE: 24/02/2020
-----------------------------------------------------------------------------------------*/
USE MATH 

COMPONENT Valvula_v 
	(BOOLEAN saturado	"TRUE: vapor saturado, FALSE: vapor no saturado")

"Válvula de vapor lineal sencilla: evita lazo algebraico y relación lineal caudal-pérdida de carga"

PORTS 
	IN vapor (saturado=saturado) 	 f_in 
	OUT  vapor (saturado=saturado) f_out 
	IN analog_signal 			 Ap		"Apertura de la válvula (%)"
	
DATA 
	REAL Cf = 0.92				"Valve parameter"
	REAL Cv = 12.5515		   "Valve size parameter [-]"
DECLS
	REAL yA
CONTINUOUS
	yA = min(1.5,1.63/Cf*ssqrt((f_in.P-f_out.P)/max(f_in.P,0.0001)))   --- critic flow limitation, no lo entiendo muy bien
	f_out.W = 3.344e-8*Cf*Cv*Ap.signal/100*f_in.P*100000*(yA-0.148*yA**3.0) // Circuit A plate inputs flux [kg/s], PAG is in Pa
	
EXPAND(saturado==TRUE)	f_out.T = temp_sat_w(f_out.P)
EXPAND(saturado==FALSE)	f_out.T = f_in.T

	f_in.W = f_out.W
END COMPONENT
