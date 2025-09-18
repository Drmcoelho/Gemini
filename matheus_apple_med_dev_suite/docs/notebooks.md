# Documentação: Notebooks Didáticos

O diretório `notebooks/` contém uma série de Jupyter Notebooks projetados para ensinar de forma prática como interagir com os componentes da **Matheus Apple Med Dev Suite** a partir de um ambiente Python.

Eles são ideais para cientistas de dados, pesquisadores e desenvolvedores que desejam integrar as ferramentas da suite em seus próprios scripts de análise, aplicações ou fluxos de trabalho.

## Notebooks Disponíveis

### 1. `01_Introducao_ao_MedCLI.ipynb`

- **Objetivo**: Apresentar a ferramenta `medcli`.
- **Conteúdo**:
    - Demonstra como executar os subcomandos básicos: `fhir get`, `openfda query`, `rxnorm rxcui`, e `ctgov search`.
    - Mostra como capturar a saída JSON desses comandos usando o módulo `subprocess` do Python.
    - Ensina a parsear o JSON para extrair dados úteis e manipulá-los dentro de um script Python.

### 2. `02_Visualizacao_de_Dados_FHIR.ipynb`

- **Objetivo**: Demonstrar um ciclo completo de busca e visualização de dados clínicos.
- **Conteúdo**:
    - Usa o `medcli` para buscar recursos de `Observation` de um servidor FHIR (neste caso, medições de pressão arterial de um paciente de exemplo).
    - Utiliza a biblioteca **Pandas** para limpar, transformar e estruturar os dados em um DataFrame.
    - Emprega a biblioteca **Matplotlib** para criar um gráfico de série temporal, plotando as medições de pressão sistólica e diastólica ao longo do tempo.

### 3. `03_Automatizando_Protocolos_com_GemX.ipynb`

- **Objetivo**: Ensinar como invocar o poder do `gemini_megapack` de forma programática.
- **Conteúdo**:
    - Mostra como executar o script `gemx.sh` a partir do Python para rodar uma automação clínica (ex: `sepse_bundle.yaml`).
    - Captura a saída em Markdown gerada pelo modelo Gemini.
    - Usa a biblioteca `IPython.display` para renderizar o protocolo clínico formatado diretamente na saída da célula do notebook.
    - Discute como essa capacidade pode ser usada para integrar os protocolos de IA em aplicações maiores.

## Como Usar

Para executar esses notebooks, você precisará de um ambiente Python com Jupyter Notebook ou JupyterLab instalado, além das bibliotecas mencionadas em cada notebook (`pandas`, `matplotlib`).

```bash
# Instalar dependências (exemplo)
pip install jupyterlab pandas matplotlib

# Iniciar o JupyterLab na raiz do projeto
jupyter-lab
```

Navegue até a pasta `notebooks/` na interface do Jupyter e abra os arquivos `.ipynb`.
