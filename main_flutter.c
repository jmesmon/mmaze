#include "armv7m.h"
#include "sam3/pio.h"
#include "sam3/wdt.h"
#include "sam3/usart.h"

void init_early(void);
void init_early(void)
{
	/*
	 * sam3s1a boots with watchdog enabled & configurable once.
	 * We disable it for now.
	 */
	SAM3_WDT.mode = (1 << SAM3_WDT_MR_WDDIS);
}

/*
 * R = PA20 (PWML1 = B)
 * G = PA16 (PWML2 = C)
 * B = PA0 (PWMH0 = A)
 */

/*
 * URXD0 = PA9  = S7 = radio slave select
 * UTXD0 = PA10 = S6 = radio gpio 2
 */

/*
 * RXD0 = PA5 = D2 = free
 * TXD0 = PA6 = D3 = free
 */
static void usart0_init(void)
{
	/* Configure PIO */

	/* Enable Module Clock */

	/* Configure NVIC */

	/* Enable USART reg access */
	SAM3_USART0.write_protect_mode = SAM3_US_WPMR_WPKEY | 1 << SAM3_US_WPMR_WPEN;

	/* Configure USART mode */
	SAM3_USART0.mode
		= SAM3_US_MR_CHRL(3) /* 8 bit */
		| SAM3_US_MR_PAR(1)  /* odd parity */
		| 0 << SAM3_US_MR_SYNC /* async */
		| 1 << SAM3_US_MR_FILTER
		;
	/* Configure USART interrupts */
	SAM3_USART0.interrupt_enable
		= 1 << SAM3_US_IER_TXEMPTY
		;

	SAM3_USART0.reciver_timeout = 0;
	SAM3_USART0.transmitter_timeguard = 0;

	/* Configure Baud Rate */

	/* Enable tx */

	/* Re-protect USART registers */
}

__attribute__((noreturn))
void main(void)
{
	/* TODO: set up clocks */
	usart0_init();

	/* Give PIO control over the RGB pins */
	SAM3_PIOA.enable = (1 << 20) | (1 << 16) | (1 << 0);
	SAM3_PIOA.output_enable = (1 << 20) | (1 << 16) | (1 << 0);

	/* Drive them */
	for (;;) {
		SAM3_PIOA.set_output_data = (1 << 20) | (1 << 16) | (1 << 0);
		delay_ms(100);
		SAM3_PIOA.clear_output_data = (1 << 20) | (1 << 16) | (1 << 0);
		delay_ms(100);
	}
}
