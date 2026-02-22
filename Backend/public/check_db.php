<?php
$c = mysqli_connect('127.0.0.1', 'root', '');
$r = mysqli_query($c, 'SHOW DATABASES');
while($row = mysqli_fetch_assoc($r)) {
    echo $row['Database'] . "\n";
}
