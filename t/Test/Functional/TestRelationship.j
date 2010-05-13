@import <OJUnit/OJTestCase.j>
@import "../../DBTestCase.j"
@import "../../Application.j"
@import <IF/ObjectContext.j>
@import <IF/Log.j>

@implementation TestRelationship : DBTestCase
{
    id oc;
}

- setUp {
    [IFLog setLogMask:0x0000];
    [super setUp];
    oc = [IFObjectContext new];
    [oc disableTracking];
    // save some decoys to make sure that counting is correct
    var decoyTrunk = [IFTestTrunk new];
    [decoyTrunk setThickness:5];
    [decoyTrunk save];
    var decoyBranch = [IFTestBranch new];
    [decoyBranch setLeafCount:8];
    [decoyBranch save];
}

// These tests are a bit bogus because I'm writing them... and I know
// how to avoid the bugs in the ORM because I wrote that too...
// and it definitely has bugs/gaps.
- (void) testToMany {
    var entities = [];

    // create a trunk object
    var trunk = [IFTestTrunk new];
    [trunk setThickness:20];
    [entities addObject:trunk];
    [trunk save];
    //[oc trackEntity:trunk];
    [self assertTrue:(trunk && [trunk id]) message:"Made a new trunk object and saved it"];

    // add some objects to a to-many
    for (var l=0; l <= 2; l++ ) {
        var branch = [IFTestBranch new];
        [branch setLength:l];
        [branch setLeafCount:(6-l)];
        [entities addObject:branch];
        [trunk addObject:branch toBothSidesOfRelationshipWithKey:"branches"];
    }
    [trunk save];

    [self assert:[[trunk branches] count] equals:3 message:"Trunk has correct number of branches"];

    [self assertNotNull:oc message:"Object context exists!"];

    // re-fetch
    var rtr = [oc entity:"IFTestTrunk" withPrimaryKey:[trunk id]];
    [self assertTrue:[rtr is:trunk] message:"Refetched trunk object"];
    [self assert:[[rtr branches] count] equals:3 message:"Refetched trunk has correct number of branches"];
    //[IFLog setLogMask:0xffff];

    // TODO check the actual branches to make sure they're correct
    var br = [[trunk branches] objectAtIndex:0];
    [trunk removeObject:br fromBothSidesOfRelationshipWithKey:"branches"];
    [trunk save];
    [IFLog debug: br]
    [IFLog debug: [oc trackedInstanceOfEntity:br]];

    [self assert:[[trunk branches] count] equals:2 message:"Trunk now has 2 branches"];

    var rtr = [oc entity:"IFTestTrunk" withPrimaryKey:[trunk id]];
    [self assertTrue:[rtr is:trunk] message:"Refetched trunk again"];
    [self assert:[[rtr branches] count] equals:2 message:"Refetched trunk has 2 branches"];
    //eval(_p_setTrace);


    //[IFLog setLogMask:0x0000];

    // cleanup
    for (var i=0; i<[entities count]; i++) {
        var e = [entities objectAtIndex:i];
        [e _deleteSelf];
    }

    // TODO check cleanup was successful
}

- (void) testToOne {
    var entities = [];

    //create a root object
    var root = [IFTestRoot new];
    [root setTitle:"Foo"];
    entities[entities.length] = root;
    [root save];
    [self assertTrue:(root && [root id]) message:"Made a new root object and saved it"];

    // create a trunk object
    var trunk = [IFTestTrunk new];
    [trunk setThickness:20];
    entities[entities.length] = trunk;
    [trunk save];
    [self assertTrue:(trunk && [trunk id]) message:"Made a new trunk object and saved it"];

    [root setTrunk:trunk];
    [root save];
    [self assertNotNull:[root trunk] message:"Root and trunk related correctly"];
    [self assertNotNull:[trunk root] message:"Trunk and root related correctly"];

    // re-fetch
    var rr = [oc entity:"IFTestRoot" withPrimaryKey:[root id]];
    [self assertTrue:(rr && [rr trunk] && [[rr trunk] is:trunk]) message:"Root refetched and trunk related"];

    [rr setTrunk:nil];
    [rr save];
    [self assertNull:[rr trunk] message:"Trunk no longer related"]; 

    var rt = [oc entity:"IFTestTrunk" withPrimaryKey:[trunk id]];
    [self assertTrue:(rt == null) message:"Trunk has been deleted"];

    var rr = [oc entity:"IFTestRoot" withPrimaryKey:[root id]];
    [self assertTrue:(rr && [rr is:root]) message:"Refetched root again"];
    [self assertNull:[rr trunk] message:"Refetched root has no trunk"];

    // cleanup
    for (var i=0; i<entities.length; i++) {
        var e = entities[i];
        [e _deleteSelf];
    }
}

/*
sub test_many_to_many : Test(7) {
    my ($self) = @_;

    my $entities = [];
    my $branches = [];
    my $isOk = 1;
    foreach my $c (0..4) {
        my $b = IFTest::Entity::Branch->new();
        $b->setLength($c);
        $b->setLeafCount($c+1);
        push @$branches, $b;
        $b->save();
        $isOk = 0 unless $b->id();
        last unless $isOk;
    }
    ok($isOk, "Created branches");

    my $globules = [];
    $isOk = 1;
    foreach my $c (0..4) {
        my $g = IFTest::Entity::Globule->new();
        $g->setName("Globule $c");
        push @$globules, $g;
        $g->save();
        $isOk = 0 unless $g->id();
        last unless $isOk;
    }
    ok($isOk, "Created globules");

    # associate them via a many-2-many

    my $g0 = $globules->[0];
    my $b4 = $branches->[4];
    $g0->addObjectToBothSidesOfRelationshipWithKeyAndHints($branches->[4], "branches", { FOO => "four", BAR => "bur", } );
    $g0->addObjectToBothSidesOfRelationshipWithKeyAndHints($branches->[2], "branches", { FOO => "two", BAR => "bum", } );
    $g0->save();
    my $brs = $g0->branches();
    ok(scalar @$brs == 2, "Two branches on globule");

    $b4->addObjectToBothSidesOfRelationshipWithKeyAndHints($globules->[1], "globules", { FOO => "one", BAR => "buz", }, );
    $b4->save();
    my $gs = $b4->globules();
    ok(scalar @$gs == 2, "Two globules on branch");

    $g0->removeObjectFromBothSidesOfRelationshipWithKey($branches->[4], "branches");
    $g0->save();
    my $brs = $g0->branches();
    ok(scalar @$brs == 1, "One branch on globule");
    # shame this is _deprecated_...
    ok($brs->[0]->_deprecated_relationshipHintForKey("FOO") eq "two", "Hint is correct");
    ok(scalar @{$b4->globules()}, "One globule on branch");

    # cleanup
    foreach my $e (@$entities) {
        $e->_deleteSelf();
    }

    # TODO check cleanup was successful
}

*/
@end
