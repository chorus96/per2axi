# `per2axi_v1_0.tcl` 분석

## 개요
이 스크립트는 `per2axi` IP의 Vivado XGUI(파라미터 UI) 동작을 정의합니다.

- GUI 파라미터 페이지 생성
- 각 파라미터의 업데이트/검증 콜백 정의
- GUI 파라미터 값을 HDL 모델 파라미터(`MODELPARAM_VALUE`)로 전달

## 파라미터 구조
`init_gui`에서 아래 파라미터를 UI에 노출합니다.

- `NB_CORES`
- `PER_ADDR_WIDTH`
- `PER_ID_WIDTH`
- `AXI_ADDR_WIDTH`
- `AXI_DATA_WIDTH`
- `AXI_USER_WIDTH`
- `AXI_ID_WIDTH`
- `AXI_STRB_WIDTH`

## 특이 로직
### `AXI_STRB_WIDTH` 자동 계산
`update_PARAM_VALUE.AXI_STRB_WIDTH`에서
- `AXI_DATA_WIDTH`가 양의 정수이면
- `AXI_STRB_WIDTH = AXI_DATA_WIDTH / 8`로 자동 설정

즉 바이트 스트로브 폭을 데이터 폭에 맞춰 동기화합니다.

## Block Diagram
```mermaid
flowchart TD
    A[Open IP Customization GUI] --> B[init_gui]
    B --> C[Create Parameters page]
    C --> D[Expose user parameters]
    D --> E[User edits parameter values]
    E --> F{Update callbacks}
    F --> G[Generic update procs\n(no-op)]
    F --> H[AXI_STRB_WIDTH update\nAXI_DATA_WIDTH/8]
    G --> I[Validate callbacks\nall return true]
    H --> I
    I --> J[update_MODELPARAM_VALUE.*]
    J --> K[Propagate to HDL model params]
    K --> L[Elaboration/Synthesis uses updated widths]
```

## 프로시저 역할 정리
- `update_PARAM_VALUE.*`: UI 값 변경 시 후처리
- `validate_PARAM_VALUE.*`: 파라미터 유효성 검사 (현재는 모두 `true`)
- `update_MODELPARAM_VALUE.*`: UI 값을 RTL 제네릭/파라미터로 전달

## 해석상 주의점
- 검증 함수가 모두 `true`이므로 범위/정합성 강제는 사실상 없습니다.
- `AXI_STRB_WIDTH` 계산은 정수/양수 확인만 하며, 나눗셈 결과가 정수라는 전제(일반적 AXI 관례: `AXI_DATA_WIDTH`는 8의 배수)를 기대합니다.
