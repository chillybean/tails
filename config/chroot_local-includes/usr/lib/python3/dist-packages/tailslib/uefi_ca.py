from dataclasses import dataclass, asdict


@dataclass
class Detection:
    action_needed: bool

    def asdict(self):
        return asdict(self)

    @classmethod
    def fromdict(cls, d):
        return cls(**d)

