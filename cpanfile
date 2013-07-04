requires 'perl', '5.008001';
requires 'Net::Twitter::Lite::WithAPIv1_1';
requires 'Data::UUID::MT';
requires 'Nephia::DSLModifier';


on 'test' => sub {
    requires 'Test::More', '0.98';
};

