#! /usr/bin/env sh

# SMP - Symmetric MultiProcessing
# RPS - Receive Packet Steering

smp1=3
rps1=2
smp2=3
rps2=2

ens3_irq=$(grep ens3 /proc/interrupts | awk '{ print $1+0 }')

# set balancer for enp1s0
echo ${smp1} > /proc/irq/${ens3_irq}/smp_affinity
# echo ${smp1} > /proc/irq/37/smp_affinity
# echo ${smp1} > /proc/irq/38/smp_affinity
# echo ${smp1} > /proc/irq/39/smp_affinity
# echo ${smp1} > /proc/irq/40/smp_affinity

# set rps for ens3
echo ${rps1} > /sys/class/net/ens3/queues/rx-0/rps_cpus
# echo ${rps1} > /sys/class/net/ens3/queues/rx-1/rps_cpus
# echo ${rps1} > /sys/class/net/ens3/queues/rx-2/rps_cpus
# echo ${rps1} > /sys/class/net/ens3/queues/rx-3/rps_cpus

ens5_irq=$(grep ens5 /proc/interrupts | awk '{ print $1+0 }')

# set balancer for enp2s0
# echo ${smp2} > /proc/irq/${ens5_irq}/smp_affinity

# echo ${smp2} > /proc/irq/43/smp_affinity
# echo ${smp2} > /proc/irq/44/smp_affinity
# echo ${smp2} > /proc/irq/45/smp_affinity
# echo ${smp2} > /proc/irq/46/smp_affinity

# set rps for ens5
echo ${rps2} > /sys/class/net/ens5/queues/rx-0/rps_cpus
# echo ${rps2} > /sys/class/net/ens5/queues/rx-1/rps_cpus
# echo ${rps2} > /sys/class/net/ens5/queues/rx-2/rps_cpus
# echo ${rps2} > /sys/class/net/ens5/queues/rx-3/rps_cpus
