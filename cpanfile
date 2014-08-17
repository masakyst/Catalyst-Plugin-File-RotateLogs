requires 'perl', '5.010_001';
requires 'File::RotateLogs', '0.07';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

