# Synchronous FIFO Verification Plan

## 1.reset

### 激励
拉低 reset 若干周期后释放

### 检查方法
检查 empty、full、count

### 通过标准
- empty = 1
- full = 0
- count = 0

### 对应测试
test_reset()

## 2.Empty Read

### 激励
empty=1,rd_en=1

### 检查方法
queue应保持为空，与测试后的DUT进行对比

### 通过标准
count保持为0

### 对应测试
test_empty_read()

## 3.Full Write

### 激励
full=1,wr_en=1

### 检查方法
queue应保持为满，与测试后的DUT比大小;检查write是否进行

### 通过标准
queue和DUT大小相同，均为满，full保持为1，DUT数据不改变，即写操作未进行

### 对应测试
test_full_write()

## 4.Consecutive R&W

### 激励
rd_en=1或wr_en=1

### 检查方法
连续写若干次，再连续读若干次，pop_front()与rd_data比较

### 通过标准
所有数据均一样，queue与DUT的大小保持一致

### 对应测试
test_consecutive_rw()

## 5.Simultaneous R&W

### 激励
wr_en=1,wr_en=1

### 检查方法
queue与DUT读写操作同时进行

### 通过标准
queue和DUT数据保持一致

### 对应测试
test_simultaneous_rw()

## 6.Wrap Around

### 激励
读写交替使指针绕回

### 检查方法
与queue全称比较

### 通过标准
指针回绕后数据仍正确

### 对应测试
test_wraparound()

## 7.Mid Reset

### 激励
resetn=0,FIFO中存在数据

### 检查方法
ref_q.delete()

### 通过标准
reset后均回到初始状态

### 对应测试
test_mid_reset()
