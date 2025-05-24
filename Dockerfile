FROM dunglas/frankenphp

RUN echo "<?php\n" \
    "echo 'Hello World';\n" \
    "?>" > index.php
