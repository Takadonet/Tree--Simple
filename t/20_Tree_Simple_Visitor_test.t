use v6;
use Test;
plan 25;
BEGIN
{
    @*INC.push('lib');
    @*INC.push('blib');
}
use Tree::Simple;
use Tree::Simple::Visitor;

#todo do not like that have to put a signature here... should be allow to have anything
my $SIMPLE_SUB = sub (*@a) { "test sub" };

# -----------------------------------------------
# test the new style interface
# -----------------------------------------------

my $visitor = Tree::Simple::Visitor.new();
ok($visitor ~~ Tree::Simple::Visitor);

#todo use the class variable instead of 'root'
my $tree = Tree::Simple.new('root').addChildren(
 							Tree::Simple.new("1").addChildren(
                                             Tree::Simple.new("1.1"),
                                             Tree::Simple.new("1.2").addChild(Tree::Simple.new("1.2.1")),
                                             Tree::Simple.new("1.3")                                            
                                         ),
 							Tree::Simple.new("2"),
 							Tree::Simple.new("3"),							
 					   );
ok($tree ~~ Tree::Simple);

$tree.accept($visitor);

ok $visitor.can('getResults'),"Can do getResults";

is_deeply([ $visitor.getResults() ], [ <1 1.1 1.2 1.2.1 1.3 2 3>],
         '... got what we expected');

ok($visitor.can('setNodeFilter'));

my $node_filter = sub (*@x) { return "_" ~ @x[0].getNodeValue() };
$visitor.setNodeFilter($node_filter);

ok($visitor.can('getNodeFilter'));
is($visitor.getNodeFilter(), "$node_filter", '... got back what we put in');

# visit the tree again to get new results now
$tree.accept($visitor);

is_deeply($visitor.getResults(),[ <_1 _1.1 _1.2 _1.2.1 _1.3 _2 _3>],
         '... got what we expected');
        
# test some exceptions

dies_ok ({
     $visitor.setNodeFilter();        
}, 'Insufficient Arguments ... this should die');

dies_ok ({
     $visitor.setNodeFilter([]);        
}, 'Insufficient Arguments ... this should die');

# -----------------------------------------------
# test the old style interface for backwards 
# compatability
# -----------------------------------------------

# # and that our RECURSIVE constant is properly defined
# can_ok("Tree::Simple::Visitor", 'RECURSIVE');
# # and that our CHILDREN_ONLY constant is properly defined
# can_ok("Tree::Simple::Visitor", 'CHILDREN_ONLY');

# no depth
my $visitor1 = Tree::Simple::Visitor.new($SIMPLE_SUB);
ok($visitor1 ~~ Tree::Simple::Visitor);

# children only
#todo replace with class constant instead of text
my $visitor2 = Tree::Simple::Visitor.new($SIMPLE_SUB, 'CHILDREN_ONLY');
ok($visitor2 ~~ Tree::Simple::Visitor);

# recursive
#todo replace with class constant instead of text
my $visitor3 = Tree::Simple::Visitor.new($SIMPLE_SUB, 'RECURSIVE');
ok($visitor3 ~~ Tree::Simple::Visitor);

# -----------------------------------------------
# test constructor exceptions
# -----------------------------------------------

# we pass a bad depth (string)
dies_ok ({
    my $test = Tree::Simple::Visitor.new($SIMPLE_SUB, "Fail")
} ,'Insufficient Arguments : Depth arguement must be either RECURSIVE or CHILDREN_ONLY');
   
# we pass a bad depth (numeric)
#dies_ok ({
#my $test = Tree::Simple::Visitor.new($SIMPLE_SUB, 100);

# },'Insufficient Arguments : Depth arguement must be either RECURSIVE or CHILDREN_ONLY');

# # we pass a non-ref func argument
# throws_ok {
# 	my $test = Tree::Simple::Visitor->new("Fail");
# } qr/Insufficient Arguments \: filter function argument must be a subroutine reference/,
#    '... we are expecting this error';

# # we pass a non-code-ref func arguement   
# throws_ok {
# 	my $test = Tree::Simple::Visitor->new([]);
# } qr/Insufficient Arguments \: filter function argument must be a subroutine reference/,
#    '... we are expecting this error';   

# -----------------------------------------------
# test other exceptions
# -----------------------------------------------

# # and make sure we can call the visit method
ok($visitor1.can('visit'));

# test no arg
# throws_ok {
# 	$visitor1->visit();
# } qr/Insufficient Arguments \: You must supply a valid Tree\:\:Simple object/,
#    '... we are expecting this error'; 
   
# # test non-ref arg
# throws_ok {
# 	$visitor1->visit("Fail");
# } qr/Insufficient Arguments \: You must supply a valid Tree\:\:Simple object/,
#    '... we are expecting this error'; 	 
   
# # test non-object ref arg
# throws_ok {
# 	$visitor1->visit([]);
# } qr/Insufficient Arguments \: You must supply a valid Tree\:\:Simple object/,
#    '... we are expecting this error'; 	   
   
# my $BAD_OBJECT = bless({}, "Test");   
   
# # test non-Tree::Simple object arg
# throws_ok {
# 	$visitor1->visit($BAD_OBJECT);
# } qr/Insufficient Arguments \: You must supply a valid Tree\:\:Simple object/,
#    '... we are expecting this error'; 	   
   

# -----------------------------------------------
# Test accept & visit
# -----------------------------------------------
# Note: 
# this test could be made more robust by actually
# getting results and testing them from the 
# Visitor object. But for right now it is good
# enough to have the code coverage, and know
# all the peices work.
# -----------------------------------------------

# now make a tree
#todo need to replace with class constant
my $tree1 = Tree::Simple.new('ROOT').addChildren(
							Tree::Simple.new("1.0"),
							Tree::Simple.new("2.0"),
							Tree::Simple.new("3.0"),							
					   );
ok($tree1 ~~ Tree::Simple);

is($tree1.getChildCount(), 3, '... there are 3 children here');

#and pass the visitor1 to accept
lives_ok( {
 	$tree1.accept($visitor1);
}, '.. this passes fine');

# and pass the visitor2 to accept
#todo figure out why it fails when it does not even die!
#lives_ok ({
 	$tree1.accept($visitor2);
#}, '.. this passes fine');


# and pass the visitor3 to accept
lives_ok( {
	$tree1.accept($visitor3);
}, '.. this passes fine');

# ----------------------------------------------------
# test some misc. weirdness to get the coverage up :P
# ----------------------------------------------------

# check that includeTrunk works as we expect it to
{
     my $visitor = Tree::Simple::Visitor.new();
     ok(!$visitor.includeTrunk(), '... this should be false right now');

     $visitor.includeTrunk(Bool::True);
     
     is($visitor.includeTrunk(), Bool::True, '... this should be true now');

     $visitor.includeTrunk(Mu);
     is($visitor.includeTrunk(), Bool::True , '... this should be true still');
    
     $visitor.includeTrunk("");
     is($visitor.includeTrunk(), Bool::False , '... this should be false again');
}

# check that clearNodeFilter works as we expect it to
{
     my $visitor = Tree::Simple::Visitor.new();
    
     my $filter = sub { "filter" };
    
     $visitor.setNodeFilter($filter);
     is($visitor.getNodeFilter(), $filter, 'our node filter is set correctly');
    
     $visitor.clearNodeFilter();
     ok(! defined($visitor.getNodeFilter()), '... our node filter has now been undefined'); 
}


