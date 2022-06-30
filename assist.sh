#!/bin/bash
###
 # @Author: LinkLeong link@icewhale.com
 # @Date: 2022-02-17 18:53:29
 # @LastEditors: a624669980@163.com a624669980@163.com
 # @LastEditTime: 2022-06-30 10:11:31
 # @FilePath: /get/assist.sh
 # @Description: 
 # @Website: https://www.casaos.io
 # Copyright (c) 2022 by icewhale, All Rights Reserved. 
### 

version_0_2_11() {
  sysctl -w net.core.rmem_max=2500000
}

version_0_2_11