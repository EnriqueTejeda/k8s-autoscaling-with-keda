.PHONY: apply destroy
apply:
	@cd terraform && terraform apply --auto-approve
destroy:
	@cd terraform && terraform destroy --auto-approve
