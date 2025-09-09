#
# Build from the git repository
#

TARG=../bin/eesolar.yaml
echo the targ is $TARG 

cat yaml/helpers/* > $TARG
echo >> $TARG
echo "automation:" >> $TARG
cat yaml/tracking/* >> $TARG
echo >> $TARG
cat yaml/rules/* >> $TARG 

cp ../bin/eesolar.yaml /config/mypackages/

