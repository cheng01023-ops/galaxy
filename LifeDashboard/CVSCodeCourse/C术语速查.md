# C 术语速查

## 基本类型

| 类型 | 说明 | printf 占位符 |
|---|---|---|
| int | 整数 | %d |
| double | 双精度小数 | %f |
| float | 单精度小数 | %f |
| char | 单个字符 | %c |
| _Bool | 布尔（0/1） | %d |

## 常用库

| 头文件 | 用途 |
|---|---|
| stdio.h | printf / scanf / 文件 |
| stdlib.h | malloc / free / 退出 |
| string.h | strcpy / strlen / strcmp |
| time.h | 时间与随机数 |

## 指针要点

- `&` 取地址
- `*` 解引用
- `p->x` 等价于 `(*p).x`
- malloc 后必须 free
- 指针用完置 NULL，避免野指针
