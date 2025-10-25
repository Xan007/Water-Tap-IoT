package com.hydro.watertap.repository;

import com.hydro.watertap.model.entity.AiSettingsEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface AiSettingsRepository extends JpaRepository<AiSettingsEntity, Long> {
}

