SCHEMA BasicTest
ROOT Sender: send;
ROOT Receiver: receive;

COORDINATE $x: send FROM Sender,
           $y: receive FROM Receiver
    DO ADD $x PRECEDES $y; OD;
