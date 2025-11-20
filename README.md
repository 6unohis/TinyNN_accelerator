# Tiny Neural Network Accelerator
(Verilog RTL)  
**Full Report:** [/mnt/data/project_report.pdf](sandbox:/mnt/data/project_report.pdf)

## Overview
본 프로젝트는 4×4 Output-Stationary Systolic Array를 활용해 구성한  
**Tiny Neural Network Accelerator (FC1 → Norm → ReLU → FC2)** 구현을 목표로 한다.

- FC1: 8×8 연산 (tiling 4×4 × 8회)
- Normalization: 32로 나누는 shift 연산
- ReLU: 음수 제거
- FC2: 8×8 연산
- Batch 모드: 8-batch / 16-batch 지원


## Architecture
### Pipeline
```
X → FC1 → Norm → ReLU → FC2 → Y
```

### Top-level Features
- Clock: 100 MHz  
- 입력 X, 가중치 W1/W2, 출력 Y 메모리 기반 구조  
- FSM: IDLE → FC1 → NORM → RELU → FC2 → WRITE_OUT → DONE  
- 결과는 memory x1에 16bit로 저장됨


## Performance Summary
| 항목 | 8-batch | 16-batch |
|------|---------|----------|
| Latency | 13.82 µs | 28.01 µs |
| Peak Bandwidth | 200 MB/s | 동일 |
| Peak Performance | 0.8 GOPS | 동일 |
| Utilization | 55% | 54% |



## Simulation
- Vivado behavioral simulation 기반  
- 8-batch, 16-batch 모두 정상 출력  
- Reference 텍스트 파일과 출력 일치  
- FC / Norm / ReLU / FC2의 intermediate 값 및 memory write 확인 완료


## How to Run
1. Vivado 프로젝트 생성 후 RTL 및 테스트벤치 추가  
2. `TEST_MODE`: 0 → 8batch / 1 → 16batch  
3. Behavioral Simulation 실행  
4. 콘솔에서 모든 출력 확인 후 `"success"` 문구 확인


## Notes
- Norm/ReLU 과정에서 메모리 접근으로 인한 지연 존재  
- Double-buffering 또는 pipeline 적용 시 latency 및 utilization 개선 가능  
- Systolic array 크기 확장 시 latency 감소 가능
