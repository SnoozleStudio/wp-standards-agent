<?php
/**
 * Plugin Name: Hello, Over the Rainbow
 * Description: A tribute to Hello Dolly — a line from Israel Kamakawiwoʻole's Over the Rainbow, every time you open the admin.
 * Version: 1.0.0
 * Requires at least: 7.0
 * Requires PHP: 8.2
 * Author: Snoozle Studio
 * License: GPL-2.0-or-later
 * Text Domain: hello-over-the-rainbow
 * Domain Path: /languages
 *
 * @package Hello_Over_The_Rainbow
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * Returns the lyric lines of Israel Kamakawiwoʻole's "Over the Rainbow".
 *
 * @return array<int, string> The lyric lines, translated.
 */
function hotr_get_lyrics() {
	$lyrics = array(
		__( 'Somewhere over the rainbow, way up high', 'hello-over-the-rainbow' ),
		__( 'And the dreams that you dream of once in a lullaby', 'hello-over-the-rainbow' ),
		__( 'Somewhere over the rainbow, bluebirds fly', 'hello-over-the-rainbow' ),
		__( 'And the dreams that you dream of, dreams really do come true, ooh yeah', 'hello-over-the-rainbow' ),
		__( "Someday I'll wish upon a star", 'hello-over-the-rainbow' ),
		__( 'And wake where the clouds are far behind me', 'hello-over-the-rainbow' ),
		__( 'Where troubles melt like lemon drops', 'hello-over-the-rainbow' ),
		__( 'Away above the chimney tops', 'hello-over-the-rainbow' ),
		__( "That's where you'll find me", 'hello-over-the-rainbow' ),
	);

	return $lyrics;
}

/**
 * Prints a random lyric line in the admin.
 *
 * @return void
 */
function hotr_print_lyric() {
	$lyrics = hotr_get_lyrics();
	$chosen = $lyrics[ wp_rand( 0, count( $lyrics ) - 1 ) ];

	echo '<p id="hello-over-the-rainbow">' . esc_html( $chosen ) . '</p>';
}

add_action( 'admin_notices', 'hotr_print_lyric' );
