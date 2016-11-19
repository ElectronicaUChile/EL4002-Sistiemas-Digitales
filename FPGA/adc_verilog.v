`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Nombre: ADC Spartan 3E Starter Board - Verilog
// Autor: Christopher E. Muñoz P.
// Fecha: Mayo - 2015
// Email: chmunozp@live.cl
//////////////////////////////////////////////////////////////////////////////////

// Definicion del modulo, donde se declaran entradas y salidas
module adc_verilog(CLK_IN, SPI_MISO, AD_CONV, SPI_SCK, SPI_SS_B, AMP_CS,
	SF_CE0, FPGA_INIT_B, DAC_CS, SPI_MOSI, AMP_SHDN, DATA);

// Declaracion de entradas
	input CLK_IN;		// Reloj de entrada
	input SPI_MISO;		// Master-Input Slave-Output del SPI

// Declaracion de salidas
	output reg AMP_CS = 1;										// Chip Select del preamplificador
	output SPI_MOSI, AD_CONV, SPI_SCK;							// Salidas del maestro y entradas del esclavo
	output SPI_SS_B, SF_CE0, FPGA_INIT_B, AMP_SHDN, DAC_CS;		// Conexiones no utilizadas
	output [13:0] DATA;											// Salida del dato convertido
	
// Variables enteras para contadores
	integer counter_adc = 0;			// Contador para la maquina de estados del conversor analogo-digital
	integer counter_preamp = 0;			// Contador para la maquina de estados del preamplificador
	integer clk_divider_adc = 0;			// Contador para el divisor de reloj del conversor analogo-digital
	integer clk_divider_preamp = 0;		// Contador para el divisor de reloj del preamplificador

// Registros que indican estado del conversor
	reg init = 0;			// Registro que indica si configuro el preamplificador
	reg data_conv = 0;		// Registro que indica el inicio de la conversion del dato

// Registros que manipulan el dato convertido
	reg [13:0] data_in = 14'b0;		// Buffer para guardar los bits de la conversion 
	reg [13:0] in_buffer = 14'b0;	// Buffer para guardar el dato resultante

// Registros
	reg SPI_SCK_REG = 0;	// Registro utilizado para el reloj del SPI
	reg SPI_MOSI_REG = 0;	// Registro del Master-Output Salve-Input del SPI
	reg AD_CONV_REG = 0;	// Registro del Chip Select del conversor analogo-digital
	reg CLK_AMP = 0;		// Registro del reloj del preamplificador
	reg CLK_ADC = 0;		// Registrod el reloj del conversor analogo-digital

// Parametro para configurar el preamplificador
	parameter preamp_gain = 8'b00010001;	// Parametro para el preamplificador

// Asignaciones continuas
	assign DATA = in_buffer;						// Asignacion de la salida del dato con el
													// buffer del dato convertido
	assign SPI_MOSI = SPI_MOSI_REG;					// Asignacion del Master-Output Salve-Input del SPI
	assign SPI_SCK = init ? SPI_SCK_REG : CLK_AMP;	// Multiplexor para el reloj del preamplificador
													// y el conversor analogo-digital
	assign AD_CONV = AD_CONV_REG;					// Asignacion del Chip Select del conversor analogo-digital
	assign SPI_SS_B = 1; 							// Conexion no utilizada
	assign SF_CE0 = 1;								// Conexion no utilizada
	assign DAC_CS = 1;								// Conexion no utilizada
	assign FPGA_INIT_B = 0;							// Conexion no utilizada
	assign AMP_SHDN = 0;							// Conexion no utilizada
	
// Divisor de reloj para el conversor analogo-digital
	always@(posedge CLK_IN)
	begin
		if(clk_divider_adc == 1)
		begin
			CLK_ADC <= ~CLK_ADC;
			clk_divider_adc <= 0;
		end
		else
			clk_divider_adc <= clk_divider_adc + 1;
	end
	
// Divisor de reloj para el preamplificador
	always@(posedge CLK_IN)
	begin
		if(clk_divider_preamp == 20)
		begin
			clk_divider_preamp <= 0;
			CLK_AMP <= ~CLK_AMP;
		end
		else
			clk_divider_preamp <= clk_divider_preamp + 1;
	end
	
// Elige cuando elegir
	always@(CLK_ADC, data_conv)
	begin
		SPI_SCK_REG = data_conv ? CLK_ADC : 0;
	end

// Maquina de estados dedicada a comunicarse con el conversor
// analogo-digital usando protocolo SPI.
	always@(negedge CLK_ADC)
	begin
		if(init == 1)
		begin
			if(data_conv == 0)
			begin
				AD_CONV_REG <= 1;
				data_conv <= 1;
				counter_adc <= 0;
				data_in <= 14'b0;
			end
			else if(data_conv == 1)
			begin
				AD_CONV_REG <= 0;
				data_in[13:1] <= data_in[12:0];
				data_in[0] <= SPI_MISO;
				counter_adc <= counter_adc + 1;
				if(counter_adc == 16)
					in_buffer <= data_in;
				else if(counter_adc == 33)
				begin
					counter_adc <= 0;
					data_conv <= 0;
				end
			end
		end
	end

// Maquina de estados encargada de la inicializacion del preamplificador.
	always@(negedge CLK_AMP)
	begin
		if(init == 0)
		begin
			AMP_CS <= 0;
			SPI_MOSI_REG <= preamp_gain[7 - counter_preamp];
			counter_preamp <= counter_preamp + 1;
			if(counter_preamp == 8)
			begin
				SPI_MOSI_REG <= 0;
				counter_preamp <= 0;
				init <= 1;
				AMP_CS <= 1;
			end
		end
	end
	
endmodule
