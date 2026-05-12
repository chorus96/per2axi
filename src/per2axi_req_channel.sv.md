# `per2axi_req_channel.sv` 상세 분석

## 개요

`per2axi_req_channel`은 peripheral interconnect의 단일 request 채널을 AXI4 master의 AW/AR/W 채널로 변환하는 조합 논리 중심의 모듈입니다. peripheral 쪽의 32-bit 데이터와 byte enable을 AXI 데이터 폭(`AXI_DATA_WIDTH`, 기본 64 bit)에 맞춰 하위/상위 32-bit lane으로 배치하고, peripheral one-hot ID를 AXI binary ID로 디코딩합니다. 또한 read request의 ID와 주소를 response 채널이 사용할 수 있도록 `trans_*` 제어 신호로 전달합니다.

> 코드 주석은 `per_slave_we_i == 0`을 write, `per_slave_we_i == 1`을 read로 설명합니다. 이 분석도 실제 RTL 조건과 주석을 기준으로 작성했습니다.

## 블록 다이어그램

```mermaid
flowchart LR
    subgraph PER[Peripheral request]
      req[per_slave_req_i]
      we[per_slave_we_i]
      add[per_slave_add_i]
      wdata[per_slave_wdata_i]
      be[per_slave_be_i]
      pid[per_slave_id_i one-hot]
    end

    subgraph REQ[per2axi_req_channel]
      ctrl[Request decoder\nwrite: req & !we\nread: req & we]
      iddec[One-hot to binary\nID decoder]
      lane[32-bit lane mapper\naddr[2] selects low/high lane]
      size[AXI size generator\nfrom byte enable]
      fixed[Fixed AXI attributes\nburst/prot/cache/user/etc.]
      grant[Grant generator\nAW & AR & W ready]
    end

    subgraph AXI[AXI master request side]
      aw[AW channel]
      ar[AR channel]
      w[W channel]
    end

    req --> ctrl
    we --> ctrl
    add --> ctrl
    add --> lane
    add --> aw
    add --> ar
    wdata --> lane
    be --> lane
    be --> size
    pid --> iddec
    iddec --> aw
    iddec --> ar
    lane --> w
    size --> aw
    size --> ar
    fixed --> aw
    fixed --> ar
    fixed --> w
    ctrl --> aw
    ctrl --> ar
    ctrl --> w
    awready[axi_master_aw_ready_i] --> grant
    arready[axi_master_ar_ready_i] --> grant
    wready[axi_master_w_ready_i] --> grant
    grant --> gnt[per_slave_gnt_o]
    ar --> trans[trans_req_o / trans_id_o / trans_add_o]
```

## 파라미터

| 파라미터 | 기본값 | 설명 |
| --- | --- | --- |
| `PER_ADDR_WIDTH` | 32 | peripheral 주소 폭입니다. |
| `PER_ID_WIDTH` | 5 | peripheral ID one-hot 벡터 폭입니다. |
| `AXI_ADDR_WIDTH` | 32 | AXI 주소 폭입니다. |
| `AXI_DATA_WIDTH` | 64 | AXI write data 폭입니다. 본 RTL은 32-bit peripheral 데이터를 64-bit AXI lane에 배치합니다. |
| `AXI_USER_WIDTH` | 6 | AXI user 신호 폭입니다. 현재 0으로 tie-off됩니다. |
| `AXI_ID_WIDTH` | 3 | AXI binary ID 폭입니다. |
| `AXI_STRB_WIDTH` | `AXI_DATA_WIDTH/8` | AXI strobe 폭입니다. local 성격의 파라미터로 주석상 override하지 말아야 합니다. |

## 주요 포트 그룹

### Peripheral request 입력

* `per_slave_req_i`: peripheral 요청 valid입니다.
* `per_slave_add_i`: AXI AW/AR 주소로 그대로 전달됩니다.
* `per_slave_we_i`: RTL 기준 `0`이면 write request, `1`이면 read request입니다.
* `per_slave_wdata_i`: write 시 AXI W data의 32-bit lane으로 배치됩니다.
* `per_slave_be_i`: write strobe 및 AXI transfer size 계산에 사용됩니다.
* `per_slave_id_i`: one-hot peripheral ID이며 AXI ID로 디코딩됩니다.
* `per_slave_gnt_o`: AXI request 관련 ready가 모두 1일 때 grant됩니다.

### AXI request 출력

* AW 채널은 write request(`per_slave_req_i & !per_slave_we_i`)에서 AW/W ready가 모두 1일 때 valid됩니다.
* W 채널은 AW와 같은 조건에서 valid되며 `axi_master_w_last_o`도 1이 됩니다. 단일 beat write만 생성합니다.
* AR 채널은 read request(`per_slave_req_i & per_slave_we_i`)에서 AR ready가 1일 때 valid됩니다.

### Response 제어 출력

* `trans_req_o`: AR valid와 동일합니다. 즉 read request가 AXI AR로 발행될 때 1입니다.
* `trans_id_o`: 해당 read의 AXI ID입니다.
* `trans_add_o`: 해당 read의 AXI 주소입니다. response 채널은 주소 bit 2를 저장해 64-bit R data 중 어느 32-bit lane을 반환할지 결정합니다.

## 동작 상세

### Request valid 생성

* write 조건: `per_slave_req_i=1`, `per_slave_we_i=0`, `axi_master_aw_ready_i=1`, `axi_master_w_ready_i=1`
  * `axi_master_aw_valid_o=1`
  * `axi_master_w_valid_o=1`
  * `axi_master_w_last_o=1`
* read 조건: `per_slave_req_i=1`, `per_slave_we_i=1`, `axi_master_ar_ready_i=1`
  * `axi_master_ar_valid_o=1`
* 조건이 만족되지 않으면 모든 valid 및 W last는 0입니다.

### 주소 전달

`axi_master_aw_addr_o`와 `axi_master_ar_addr_o`는 `per_slave_add_i`를 그대로 사용합니다. 별도의 정렬/마스킹은 수행하지 않습니다.

### ID 디코딩

`per_slave_id_i`의 set bit 위치를 순회하여 해당 인덱스를 `axi_master_aw_id_o`와 `axi_master_ar_id_o`에 할당합니다. 둘 이상의 bit가 1이면 for-loop 후반의 더 큰 인덱스가 최종 값으로 남습니다.

### Write data 및 strobe lane 배치

| `per_slave_add_i[2]` | `axi_master_w_data_o` | `axi_master_w_strb_o` | 의미 |
| --- | --- | --- | --- |
| 0 | `{32'b0, per_slave_wdata_i}` | `{4'b0, per_slave_be_i}` | 64-bit AXI word의 하위 32-bit lane 사용 |
| 1 | `{per_slave_wdata_i, 32'b0}` | `{per_slave_be_i, 4'b0}` | 64-bit AXI word의 상위 32-bit lane 사용 |

### AXI size 생성

`per_slave_be_i` 패턴에 따라 AW/AR `size`가 결정됩니다.

| Byte enable 패턴 | AXI size | 전송 크기 |
| --- | --- | --- |
| `0001`, `0010`, `0100`, `1000` | `3'b000` | 1 byte |
| `0011`, `0110`, `1100` | `3'b001` | 2 bytes |
| `1111` | `3'b010` | 4 bytes |
| 기타 패턴 | 기본값 `3'b000` 유지 | RTL은 명시적 에러 처리를 하지 않음 |

### Grant 생성

`per_slave_gnt_o = axi_master_aw_ready_i && axi_master_ar_ready_i && axi_master_w_ready_i`입니다. 현재 요청이 read인지 write인지와 무관하게 세 ready가 모두 1이어야 grant됩니다. 따라서 한쪽 채널만 필요한 트랜잭션이어도 사용하지 않는 ready가 0이면 grant가 내려가지 않습니다.

### 고정 AXI 속성

* `burst`는 AW/AR 모두 `2'b01`로 고정되어 INCR burst를 의미합니다.
* `len`은 0으로 tie-off되어 단일 beat를 의미합니다.
* `prot`, `region`, `lock`, `cache`, `qos`, `user`는 0으로 tie-off됩니다.
* W `user`도 0으로 tie-off됩니다.

## 설계상 유의점

* 이 모듈은 클록/리셋이 없는 조합 논리 모듈입니다. buffering은 상위 `per2axi`의 AXI channel buffer들이 담당합니다.
* 32-bit peripheral request를 64-bit AXI data bus에 얹는 구조이므로 주소 bit 2가 lane 선택에 중요합니다.
* `PER_ID_WIDTH`와 `AXI_ID_WIDTH` 조합은 모든 peripheral ID 인덱스를 표현할 수 있어야 합니다. 기본값 5 one-hot ID는 3-bit AXI ID로 표현 가능합니다.
* AXI response error(`resp`)에 대한 처리는 request 채널에 없습니다. response 채널도 현재 `opc`를 0으로 고정합니다.

## 의사 코드

```text
aw_valid = req && !we && aw_ready && w_ready
w_valid  = req && !we && aw_ready && w_ready
w_last   = w_valid
ar_valid = req &&  we && ar_ready

gnt = aw_ready && ar_ready && w_ready

axi_id = index_of_highest_set_bit(per_slave_id)
axi_addr = per_slave_add

if addr[2] == 0:
  w_data = zero_extend_upper_32(per_slave_wdata)
  w_strb = {4'b0, be}
else:
  w_data = place_in_upper_32(per_slave_wdata)
  w_strb = {be, 4'b0}

size = size_from_byte_enable(be)
trans_req = ar_valid
trans_id  = ar_id
trans_add = ar_addr
```
