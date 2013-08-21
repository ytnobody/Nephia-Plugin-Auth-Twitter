requires 'perl', '5.008001';
requires 'Net::Twitter::Lite::WithAPIv1_1';
requires 'Data::UUID::MT';
requires 'PrimalNephia::DSLModifier';
requires 'Net::OAuth', '0.25';


on 'test' => sub {
    requires 'Test::More', '0.98';
};

