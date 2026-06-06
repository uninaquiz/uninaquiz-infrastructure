# 🎓 UninaQuiz - Infraestrutura

Infraestrutura como código (IaC) para o backend da aplicação **UninaQuiz**, utilizando **Terraform** para provisionar recursos na **AWS**.

## 📋 Visão Geral

Este repositório contém toda a configuração Terraform necessária para provisionar e gerenciar a infraestrutura do backend UninaQuiz na AWS. A aplicação é um binário Go compilado que roda diretamente em uma instância EC2, gerenciado pelo **systemd**.

O banco de dados PostgreSQL é gerenciado externamente pelo **Supabase** e não faz parte desta infraestrutura.

## 🏗️ Arquitetura

```
                    ┌─────────────────────────────────────────────┐
                    │                  AWS Cloud                  │
                    │                                             │
                    │  ┌───────────────────────────────────────┐  │
                    │  │         VPC (10.0.0.0/16)             │  │
                    │  │                                       │  │
                    │  │  ┌─────────────────────────────────┐  │  │
                    │  │  │    Sub-rede Pública              │  │  │
                    │  │  │    (10.0.1.0/24)                 │  │  │
                    │  │  │                                  │  │  │
  Usuários ──────── │──│──│──► EC2 (Amazon Linux 2023)       │  │  │
  (Internet)   ─────│──│──│──►  ├── uninaquiz-backend (Go)   │  │  │
                    │  │  │     ├── systemd service           │  │  │
                    │  │  │     └── Porta 8080                │  │  │
                    │  │  │                                  │  │  │
                    │  │  └─────────────────────────────────┘  │  │
                    │  │                    │                   │  │
                    │  │              Internet Gateway          │  │
                    │  └───────────────────────────────────────┘  │
                    │                                             │
                    └─────────────────────────────────────────────┘
                                        │
                                        ▼
                              ┌───────────────────┐
                              │     Supabase       │
                              │   (PostgreSQL)     │
                              │  (externo à AWS)   │
                              └───────────────────┘
```

## 📁 Estrutura de Arquivos

| Arquivo | Descrição |
|---------|-----------|
| `main.tf` | Configuração do Terraform, providers e tags locais |
| `variables.tf` | Definição de todas as variáveis configuráveis |
| `vpc.tf` | VPC, sub-rede pública, Internet Gateway e tabelas de rota |
| `security_groups.tf` | Grupo de segurança com regras de firewall |
| `iam.tf` | Role IAM, política e perfil de instância |
| `ec2.tf` | Instância EC2, chave SSH, AMI e script de inicialização |
| `outputs.tf` | Valores exportados após `terraform apply` |
| `terraform.tfvars.example` | Exemplo de arquivo de variáveis |

## ✅ Pré-requisitos

Antes de começar, certifique-se de ter instalado e configurado:

1. **Terraform** (>= 1.0)
   ```bash
   # Verificar instalação
   terraform --version
   ```

2. **AWS CLI** (v2)
   ```bash
   # Verificar instalação
   aws --version
   ```

3. **Credenciais AWS** configuradas
   ```bash
   # Configurar credenciais
   aws configure

   # Ou exportar variáveis de ambiente
   export AWS_ACCESS_KEY_ID="sua-access-key"
   export AWS_SECRET_ACCESS_KEY="sua-secret-key"
   export AWS_DEFAULT_REGION="us-east-2"
   ```

## 🚀 Início Rápido

### 1. Clonar o repositório

```bash
git clone https://github.com/seu-usuario/uninaquiz-infrastructure.git
cd uninaquiz-infrastructure
```

### 2. (Opcional) Personalizar variáveis

```bash
cp terraform.tfvars.example terraform.tfvars
# Edite terraform.tfvars conforme necessário
```

### 3. Inicializar o Terraform

```bash
terraform init
```

### 4. Visualizar o plano de execução

```bash
terraform plan
```

### 5. Aplicar a infraestrutura

```bash
terraform apply
```

Digite `yes` quando solicitado para confirmar a criação dos recursos.

### 6. Verificar os outputs

Após a aplicação, o Terraform exibirá informações importantes:

```bash
terraform output
```

Exemplo de saída:
```
app_url          = "http://3.15.xxx.xxx:8080"
ec2_instance_id  = "i-0abc123def456789"
ec2_public_ip    = "3.15.xxx.xxx"
health_check_url = "http://3.15.xxx.xxx:8080/api/health"
ssh_command      = "ssh -i uninaquiz-key.pem ec2-user@3.15.xxx.xxx"
vpc_id           = "vpc-0abc123def456789"
```

## 🔑 Configuração do GitHub Secrets (CI/CD)

Para que o pipeline de CI/CD funcione corretamente, configure os seguintes secrets no repositório do backend (`uninaquiz-backend`):

| Secret | Descrição | Como obter |
|--------|-----------|------------|
| `EC2_HOST` | IP público da instância EC2 | `terraform output ec2_public_ip` |
| `EC2_SSH_PRIVATE_KEY` | Chave privada SSH para acesso à instância | Conteúdo do arquivo `uninaquiz-key.pem` |

### Obtendo os valores:

```bash
# IP da instância
terraform output -raw ec2_public_ip

# Chave SSH (copie todo o conteúdo)
cat uninaquiz-key.pem
```

> **⚠️ Importante:** A chave privada (`uninaquiz-key.pem`) é gerada automaticamente pelo Terraform e **nunca deve ser commitada** no repositório. O `.gitignore` já está configurado para ignorar arquivos `.pem`.

## ⚙️ Configuração de Variáveis de Ambiente na EC2

Após o provisionamento, conecte-se à instância e configure as variáveis de ambiente:

```bash
# Conectar via SSH
ssh -i uninaquiz-key.pem ec2-user@<IP_DA_INSTANCIA>

# Editar o arquivo de variáveis de ambiente
sudo nano /opt/uninaquiz/.env
```

Preencha os valores necessários:

```env
# PostgreSQL connection string (Supabase)
DATABASE_URL=postgresql://user:password@host:5432/dbname

# Supabase project URL
SUPABASE_URL=https://your-project.supabase.co

# Supabase anonymous/service key
SUPABASE_KEY=your-supabase-key

# Application port
APP_PORT=8080
```

Após configurar, reinicie o serviço:

```bash
sudo systemctl restart uninaquiz
```

## 🛠️ Comandos Úteis

### SSH

```bash
# Conectar à instância
ssh -i uninaquiz-key.pem ec2-user@$(terraform output -raw ec2_public_ip)
```

### Gerenciamento do Serviço

```bash
# Verificar status do serviço
sudo systemctl status uninaquiz

# Iniciar o serviço
sudo systemctl start uninaquiz

# Parar o serviço
sudo systemctl stop uninaquiz

# Reiniciar o serviço
sudo systemctl restart uninaquiz

# Ver logs do serviço (em tempo real)
sudo journalctl -u uninaquiz -f

# Ver últimas 100 linhas de log
sudo journalctl -u uninaquiz -n 100

# Ver logs desde o último boot
sudo journalctl -u uninaquiz -b
```

### Health Check

```bash
# Verificar se a API está respondendo
curl http://$(terraform output -raw ec2_public_ip):8080/api/health
```

### Terraform

```bash
# Ver estado atual da infraestrutura
terraform show

# Ver outputs salvos
terraform output

# Ver output específico (sem aspas)
terraform output -raw ec2_public_ip

# Atualizar infraestrutura
terraform plan
terraform apply

# Verificar formatação dos arquivos
terraform fmt -check

# Validar configuração
terraform validate
```

## 🧹 Limpeza (Destruir Infraestrutura)

Para remover **todos** os recursos provisionados:

```bash
terraform destroy
```

> **⚠️ Atenção:** Este comando irá destruir permanentemente todos os recursos AWS criados por este Terraform, incluindo a instância EC2 e todos os dados nela contidos. Certifique-se de ter feito backup de qualquer dado importante.

## 📊 Variáveis Disponíveis

| Variável | Descrição | Padrão |
|----------|-----------|--------|
| `aws_region` | Região AWS | `us-east-2` |
| `project_name` | Nome do projeto | `uninaquiz` |
| `instance_type` | Tipo da instância EC2 | `t2.micro` |
| `vpc_cidr` | CIDR da VPC | `10.0.0.0/16` |
| `public_subnet_cidr` | CIDR da sub-rede pública | `10.0.1.0/24` |
| `app_port` | Porta da aplicação | `8080` |
| `environment` | Ambiente de deploy | `production` |

## 📄 Licença

Este projeto está licenciado sob os termos da licença MIT. Consulte o arquivo [LICENSE](LICENSE) para mais detalhes.
