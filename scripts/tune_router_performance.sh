#! /usr/bin/env sh

smp1=8
rps1=7
smp2=8
rps2=7

# set balancer for enp1s0
echo ${smp1} > /proc/irq/36/smp_affinity
echo ${smp1} > /proc/irq/37/smp_affinity
echo ${smp1} > /proc/irq/38/smp_affinity
echo ${smp1} > /proc/irq/39/smp_affinity
echo ${smp1} > /proc/irq/40/smp_affinity

# set rps for enp1s0
echo ${rps1} > /sys/class/net/enp1s0/queues/rx-0/rps_cpus
echo ${rps1} > /sys/class/net/enp1s0/queues/rx-1/rps_cpus
echo ${rps1} > /sys/class/net/enp1s0/queues/rx-2/rps_cpus
echo ${rps1} > /sys/class/net/enp1s0/queues/rx-3/rps_cpus

# set balancer for enp2s0
echo ${smp2} > /proc/irq/42/smp_affinity
echo ${smp2} > /proc/irq/43/smp_affinity
echo ${smp2} > /proc/irq/44/smp_affinity
echo ${smp2} > /proc/irq/45/smp_affinity
echo ${smp2} > /proc/irq/46/smp_affinity

# set rps for enp2s0
echo ${rps2} > /sys/class/net/enp2s0/queues/rx-0/rps_cpus
echo ${rps2} > /sys/class/net/enp2s0/queues/rx-1/rps_cpus
echo ${rps2} > /sys/class/net/enp2s0/queues/rx-2/rps_cpus
echo ${rps2} > /sys/class/net/enp2s0/queues/rx-3/rps_cpus
