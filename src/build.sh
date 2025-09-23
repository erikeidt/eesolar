#
# Build from the git repository
#

MONITOR_ONLY_TARGET=../bin/eesolar_monitor_only.yaml
FULL_TARGET=../bin/eesolar.yaml

#echo the targ is $MONITOR_ONLY_TARGET 

cat yaml/helpers/* > $MONITOR_ONLY_TARGET
echo >> $MONITOR_ONLY_TARGET

echo "automation:" >> $MONITOR_ONLY_TARGET
cat yaml/tracking/* >> $MONITOR_ONLY_TARGET

cp $MONITOR_ONLY_TARGET $FULL_TARGET
cat yaml/rules/* >> $FULL_TARGET

