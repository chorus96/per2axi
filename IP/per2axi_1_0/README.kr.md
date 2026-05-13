# per2axi AMD Vivado IP

이 디렉터리는 `per2axi` SystemVerilog 모듈을 위한 AMD Vivado 호환 custom IP
패키지를 포함합니다.

RTL 소스는 의도적으로 `component.xml`에서 **상대 경로로 참조**되며, 이 IP
디렉터리로 복사되지 않습니다. 참조되는 파일들은 이 디렉터리를 기준으로
`../../src`에 있습니다.

Vivado로 IP 메타데이터를 다시 생성하려면 repository root에서 다음 명령을
실행하세요.

```tcl
vivado -mode batch -source IP/per2axi_1_0/package_ip.tcl
```

`per2axi` RTL은 이 repository의 Bender dependency가 제공하는 `axi_slice` 버퍼
모듈도 instantiate합니다. 이 IP를 사용하는 Vivado project에서 해당 dependency
소스들을 사용할 수 있는지 확인하세요.
