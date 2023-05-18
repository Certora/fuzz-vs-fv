// Vat.spec

methods {
    debt() returns (uint256) envfree
    vice() returns (uint256) envfree
}

ghost sumOfVaultDebtGhost() returns uint256 {
    init_state axiom sumOfVaultDebtGhost() == 0;
}

ghost mapping(bytes32 => uint256) rateGhost {
    init_state axiom forall bytes32 ilk. rateGhost[ilk] == 0;
}

ghost mapping(bytes32 => uint256) ArtGhost {
    init_state axiom forall bytes32 ilk. ArtGhost[ilk] == 0;
}

hook Sload uint256 v currentContract.ilks[KEY bytes32 ilk].(offset 0) STORAGE {
    require ArtGhost[ilk] == v;
}

hook Sstore currentContract.ilks[KEY bytes32 ilk].(offset 0) uint256 newArt (uint256 oldArt) STORAGE {
    havoc sumOfVaultDebtGhost assuming sumOfVaultDebtGhost@new() == sumOfVaultDebtGhost@old() + (newArt * rateGhost[ilk]) - (oldArt * rateGhost[ilk]);
    ArtGhost[ilk] = newArt;
}

hook Sload uint256 v currentContract.ilks[KEY bytes32 ilk].(offset 32) STORAGE {
    require rateGhost[ilk] == v;
}

hook Sstore currentContract.ilks[KEY bytes32 ilk].(offset 32) uint256 newRate (uint256 oldRate) STORAGE {
    havoc sumOfVaultDebtGhost assuming sumOfVaultDebtGhost@new() == sumOfVaultDebtGhost@old() + (ArtGhost[ilk] * newRate) - (ArtGhost[ilk] * oldRate);
    rateGhost[ilk] = newRate;
}

invariant fundamental_equation_of_dai()
   debt() == vice() + sumOfVaultDebtGhost()
   filtered { f -> !f.isFallback }
