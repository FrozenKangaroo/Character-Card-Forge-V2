class_name CCFGenerationServiceV01516
extends "res://scripts/services/generation_service_v01515.gd"


# v0.15.16 deliberately contains very little new generation behaviour. The
# important fix is lower in the inheritance chain: v0.14.13 now extends the
# v0.13.5 parity stack instead of the bare base generation service. Keeping a
# versioned leaf makes the restored runtime composition explicit and gives
# integration tests a stable class to assert against.
func generation_pipeline_capabilities_v01516() -> Dictionary:
	return {
		"template_contract": self is CCFTemplateContractGuardGenerationService,
		"semantic_repair": self is CCFParityGenerationService,
		"interview": self is CCFInterviewGenerationService,
		"builder_precedence": self is CCFBuilderPrecedenceGenerationService,
		"mode_style": self is CCFModeStyleGenerationService,
		"concept_fidelity": self is CCFConceptFidelityGenerationService,
		"collaborator": has_method("queue_collaborator_reply"),
		"blueprint_handoff": has_method("queue_collaborator_blueprint")
	}
