/*-----------------------------------------------------------------------------------------
 LIBRARY: STERILIZER
 FILE: Cart_storage
 CREATION DATE: 24/03/2021
-----------------------------------------------------------------------------------------*/
USE MATH

COMPONENT Cart_storage (SET_OF(products) prod)
PORTS
	OUT analog_signal batch_ready
	IN analog_signal batch_in_ster
	IN analog_signal start
DECLS
	INTEGER cart_in = 0
	INTEGER cart_out = 0
	INTEGER n_carts = 0
	INTEGER i

	REAL v_carros								"Velocidad de producción de carros [carros/h]"
	DISCR REAL t_carga
	DISCR REAL flag = 1							" flag que previene que se entre en el primer y en el segundo when al mismo tiempo."
	
	DISCR REAL t_incr
	REAL t_gen
DISCRETE

		WHEN (batch_in_ster.signal == 1 AND start.signal == 1) THEN
			batch_ready.signal = 0
			n_carts = 0
			t_carga = TIME
			flag = 1
		END WHEN
		
		WHEN (n_carts>=12) THEN
			batch_ready.signal = 1
			flag = 0
		END WHEN

		WHEN (TIME>t_incr AND start.signal == 1) THEN
			n_carts = min(n_carts + 1,12)
			t_incr = TIME + t_gen
		END WHEN
CONTINUOUS
		SEQUENTIAL
END SEQUENTIAL
		t_gen = 3600/max(0.001,v_carros)
		
END COMPONENT



