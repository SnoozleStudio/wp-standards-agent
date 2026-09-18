<?php
/*
 * Plugin Name: Hello Over The Rainbow
 * Description: A tribute to Hello Dolly with Over the Rainbow by Israel Kamakawiwoʻole.
 * Version: 1.0.0
 */

function rainbow_get_lyrics() {
    $lyrics = [
        'Somewhere over the rainbow, way up high',
        'And the dreams that you dream of once in a lullaby',
        'Somewhere over the rainbow, bluebirds fly',
        'And the dreams that you dream of, dreams really do come true, ooh yeah',
        'Someday I\'ll wish upon a star',
        'And wake where the clouds are far behind me',
        'Where troubles melt like lemon drops',
        'Away above the chimney tops',
        'That\'s where you\'ll find me',
    ];
    return $lyrics;
}

function rainbow_hello() {
    $lyrics = rainbow_get_lyrics();
    $chosen = $lyrics[ rand( 0, count( $lyrics ) - 1 ) ];
    echo "<p id='rainbow'>$chosen</p>";
}
add_action( 'admin_notices', function () {
    rainbow_hello();
} );
