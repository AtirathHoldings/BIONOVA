package com.bionova.repository.executive;

import com.bionova.entity.executive.ExecutiveEscrowAccount;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface ExecutiveEscrowAccountRepository extends JpaRepository<ExecutiveEscrowAccount, Long> {
}

