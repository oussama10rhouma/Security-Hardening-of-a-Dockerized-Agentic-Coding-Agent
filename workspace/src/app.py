"""A tiny utility module the agent is asked to review/improve."""


def add(a: int, b: int) -> int:
    return a + b


def divide(a: float, b: float) -> float:
    # NOTE for the reviewer: no zero-division handling yet.
    return a / b


if __name__ == "__main__":
    print(add(2, 3))
