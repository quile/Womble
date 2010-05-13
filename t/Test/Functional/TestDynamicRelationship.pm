package WMTest::TestDynamicRelationship;

use strict;
use base qw(
    Test::Class
);

use Test::More;
use WMTest::Application;
use WM::ObjectContext;
use WM::Relationship::Dynamic;
use WM::Relationship::ManyToMany;


# TODO refactor this to be shared amongst tests
sub setUp : Test(startup => 5) {
    my ($self) = @_;
    
    my $entities = [];
    $self->{oc} = WM::ObjectContext->new();
    
    my $root = WMTest::Entity::Root->new();
    $root->setTitle("Root");
    push @$entities, $root;
    
    my $trunk = WMTest::Entity::Trunk->new();
    $trunk->setThickness(20);
    push @$entities, $trunk;
    
    $root->setTrunk($trunk);
    
    my $branches = [];
    my $zabs = [];
    foreach my $length (0..5) {
        my $branch = WMTest::Entity::Branch->new();
        $branch->setLength($length);
        $branch->setLeafCount(6-$length);
        
        # these are not related through the model
        my $zab = WMTest::Entity::Zab->new();
        $zab->setTitle("Zab-$length");
        $zab->save();
        push @$entities, $zab;
        push @$zabs, $zab;
        
        $branch->setZabType("Zab");
        $branch->setZabId($zab->id());
        
        push @$entities, $branch;
        push @$branches, $branch;
        $trunk->addObjectToBranches($branch);
    }
    
    my $globules = [];
    foreach my $length (0..2) {
        my $globule = WMTest::Entity::Globule->new();
        $globule->setName("Globule-$length");
        $branches->[$length]->addObjectToBothSidesOfRelationshipWithKey($globule, "globules");
        $branches->[$length]->save();
        push @$globules, $globule;
    }
    
    $root->save();
    ok($root->id(), "Root has an id now");
    ok($trunk->id(), "Trunk has an id now");
    
    ok($root->trunk() && $root->trunk()->is($trunk), "Trunk and root connected");
    ok(scalar @{$trunk->branches()} == 6, "Trunk has six branches");
    
    # make sure we have 6 zabs
    ok(scalar @{$self->{oc}->allEntities("Zab")} == 6, "6 zabs created");
    
    # # make some weird connections between entities via the "Elastic" entity
    # my $e1 = WMTest::Entity::Elastic->new();
    # $e1->setTargetType("Globule");
    # $e1->setSourceType("Zab");
    # $e1->setTargetId($globules->[0]->id());
    # $e1->setSourceId($zabs->[0]->id());
    # $e1->setPling("Zonk!");
    # $e1->save();
    # push @$entities, $e1;
    # 
    # my $ground = WMTest::Entity::Ground->new();
    # $ground->setColour("Banana yellow");
    # $ground->save();
    # push @$entities, $ground;
    # 
    # my $e2 = WMTest::Entity::Elastic->new();
    # $e2->setTargetType("Branch");
    # $e2->setSourceType("Ground");
    # $e2->setTargetId($branches->[1]->id());
    # $e2->setSourceId($ground->id());
    # $e2->setPling("Plurg!");
    # $e2->save();
    # push @$entities, $e2;   
    
    # this just assists with cleanup
    $self->{entities} = $entities;
    $self->{root} = $root;
}


sub tearDown : Test(shutdown) {
    my ($self) = @_;
    foreach my $e (@{$self->{entities}}) {
        $e->_deleteSelf();
    }
}

# tests

sub test_basic_dynamic_relationship : Test(2) {
    my ($self) = @_;
    
	# Let's start in a verbose fashion and move to something less
	# wordy and a bit smarter.  Here's verbose:
	my $dq = WM::Relationship::Dynamic->new();
	$dq->setTargetAssetTypeAttribute("zabType");
	$dq->setSourceAttributeName("zabId");
	$dq->setTargetAttributeName("id");
	$dq->setTargetAssetTypeName("Zab");

	# now that we've created it, let's see if it gets set
	# up right when we add it to a fetch spec
	my $fs = WM::FetchSpecification->new("Branch");
	$fs->addDynamicRelationshipWithName($dq, "foo");
	ok($dq->entityClassDescription() && $dq->entityClassDescription()->name() eq "Branch", "ECD gets set");	


	# let's see if prefetching works:
	$fs->setPrefetchingRelationships(["foo"]);
	$fs->setQualifier(WM::Qualifier->and([
		WM::Qualifier->key("foo.title = %@", "Zab-3"),
	]));

	my $results = $self->{oc}->entitiesMatchingFetchSpecification($fs);
	
	ok(scalar @$results && $results->[0]->_cachedEntitiesForRelationshipNamed("foo") &&
		scalar @{$results->[0]->_cachedEntitiesForRelationshipNamed("foo")}, 
		"Prefetched entities across a dynamic relationship");

}
	
sub test_qualify_across_different_relationship_types : Test(2) {
    my ($self) = @_;
    
    my $dq = WM::Relationship::Dynamic->new();
    $dq->setTargetAssetTypeAttribute("zabType");
    $dq->setSourceAttributeName("zabId");
    $dq->setTargetAttributeName("id");
    $dq->setTargetAssetTypeName("Zab");
     
    my $fs = WM::FetchSpecification->new("Branch");
    $fs->addDynamicRelationshipWithName($dq, "bar");
    $fs->setPrefetchingRelationships(["globules", "bar"]);
    $fs->setQualifier(
        WM::Qualifier->and([
            WM::Qualifier->key("bar.title = %@", "Zab-1"),
            WM::Qualifier->key("globules.name = %@", "Globule-1"),
        ])
    );
    
    my $entities = $self->{oc}->entitiesMatchingFetchSpecification($fs);
    ok(@$entities == 1, "Fetched correct number when qualifying across a dynamic relationship and a static one");

    my $count = $self->{oc}->countOfEntitiesMatchingFetchSpecification($fs);
    ok($count == 1, "counted correct number of results");
}

# TODO this will need a table with the source and target types stored in a
# column in the table...

# 
# sub test_many_to_many : Test(1) {
#     my ($self) = @_;
#     
#     # Now let's test many2many relationships.  This is
#     # doing it the raw way:
#     my $dq = WM::Relationship::ManyToMany->new();
#     # You can use these if you set the joinEntity()
#     $dq->setTargetAssetTypeAttribute("targetId");
#     $dq->setSourceAssetTypeAttribute("sourceId");  
# 
#     $dq->setJoinSourceAttribute("TARGET_ID"); # ?
#     $dq->setJoinTargetAttribute("SOURCE_ID");
#     $dq->setJoinEntity("Elastic");
#     $dq->setJoinQualifiers({
#       PLING => "Zonk!",
#     });
# 
#     # This resolves the types, which must be done before the
#     # join can take place
#     $dq->setTargetAssetTypeName("Globule");
# 
#     my $fs = WM::FetchSpecification->new("Zab");
#     $fs->addDynamicRelationshipWithName($dq, "fokker");
#     $fs->setPrefetchingRelationships(["fokker"]);
#     diag ($fs->toCountSQLFromExpression()->{SQL});
# 
#     my $count = $self->{oc}->countOfEntitiesMatchingFetchSpecification($fs);
#     diag("Counted $count users that are members of orgs");
#     ok($count > 0, "Got a positive count back");
# }

#   
#   # let's get a big more complicated; let's qualify across a 
#   # dynamic m2m.  This is still pretty raw & wordy.
#   eval {
#       my $dq = Idealist::Relationship::ManyToMany->new();
#       $dq->setTargetAssetTypeAttribute("targetAssetTypeId");
#       $dq->setSourceAssetTypeAttribute("sourceAssetTypeId");  
# 
#       $dq->setJoinSourceAttribute("TARGET_ASSET_ID");
#       $dq->setJoinTargetAttribute("SOURCE_ASSET_ID");
#       $dq->setJoinEntity("Connection");
#       $dq->setJoinQualifiers({
#           CONNECTION_TYPE_ID => 10,
#       });
#       
#       # This resolves the types, which must be done before the
#       # join can take place
#       $dq->setTargetAssetTypeName("Job");
#       
#       my $fs = WM::FetchSpecification->new("Org");
#       $fs->addDynamicRelationshipWithName($dq, "gaylord");
#       
#       # find all orgs with jobs posted in spanish
#       $fs->setQualifier(WM::Qualifier->key("gaylord.languageDesignation = %@", "es"));
#       
#       IQA_dump($fs->toCountSQLFromExpression());
#       
#       my $count = $oc->countOfEntitiesMatchingFetchSpecification($fs);
#       diag("Counted $count spanish jobs posted by orgs");
#       ok($count > 0, "Got a positive count back");
#   };
#   if ($@) {
#       ok(0, "Failed: $@");
#   }
#   
#   # what about summary specs?
#   eval {
#       my $dq = Idealist::Relationship::ManyToMany->new();
#       $dq->setTargetAssetTypeAttribute("targetAssetTypeId");
#       $dq->setSourceAssetTypeAttribute("sourceAssetTypeId");  
# 
#       $dq->setJoinSourceAttribute("TARGET_ASSET_ID");
#       $dq->setJoinTargetAttribute("SOURCE_ASSET_ID");
#       $dq->setJoinEntity("Connection");
#       $dq->setJoinQualifiers({
#           CONNECTION_TYPE_ID => 2,
#       });
#       
#       # This resolves the types, which must be done before the
#       # join can take place
#       $dq->setTargetAssetTypeName("Org");
# 
#       my $fs = WM::SummarySpecification->new("User");
#       $fs->addDynamicRelationshipWithName($dq, "zoolander");  
#       my $sa = WM::SummaryAttribute->new("count", "COUNT(*)");
#       $fs->initWithSummaryAttributes([$sa]);
#       $fs->setGroupBy(["zoolander.languageDesignation"]);
#       $fs->restrictFetchToAttributes(["count", "zoolander.languageDesignation"]);
#       #IQA_dump($fs->toSQLFromExpression());
#       
#       my $results = $oc->resultsForSummarySpecification($fs);
#       IQA_dump($results);
#       ok($results && $results->[0]->{count} > 0, "got > 0 results counted");
#   };
#   if ($@) {
#       ok(0, "Failed: $@");
#   }
# };
# if ($@) {
#   ok(0, "Failed: $@");
# }
# 
# # tear down
# diag(IQA_cleanup());

1;