# Importa os módulos necessários para criar a GUI e usar SaveFileDialog
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName System.Windows.Forms

# Criação do diretório para salvar o script e logs
$scriptDirectory = "C:\Jornada365\Intune\J365Features"
if (-Not (Test-Path $scriptDirectory)) {
    New-Item -Path $scriptDirectory -ItemType Directory | Out-Null
}

# Função para registrar logs
function Write-Log {
    param (
        [string]$Message,
        [string]$LogFile = "$scriptDirectory\JornadaFeature.log"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $LogFile -Append -Encoding UTF8
}

Write-Log "Script iniciado."

# Função para criar o cache das features do Windows
function Get-CachedWindowsFeatures {
    $cachePath = "$env:TEMP\WindowsFeaturesCache.txt"
    if (-Not (Test-Path $cachePath)) {
        Write-Log "Gerando cache de features do Windows."
        $features = Get-WindowsOptionalFeature -Online
        $features | Out-File -FilePath $cachePath -Encoding UTF8
    } else {
        Write-Log "Cache de features encontrado."
        $features = Get-Content $cachePath | ForEach-Object { $_ -split "`t" }
    }
    return $features
}

# Função para gerar um nome de arquivo aleatório baseado nas features selecionadas
function Generate-RandomScriptName {
    param (
        [array]$SelectedFeatures
    )
    $featureNames = $SelectedFeatures | ForEach-Object { $_.Content.Split(":")[1].Trim() }
    $randomFeature = ($featureNames | Get-Random)
    $date = Get-Date -Format "yyyyMMddHHmmss"
    return "Install_$randomFeature_$date.ps1"
}

# Carrega as features do cache
$CachedFeatures = Get-CachedWindowsFeatures

# Variável para armazenar features selecionadas
$SelectedFeatures = @()

# Criação da janela principal
$Window = New-Object system.Windows.Window
$Window.Title = "Windows Features | Jornada 365"
$Window.Width = 700
$Window.Height = 600
$Window.WindowStartupLocation = "CenterScreen"
$Window.Background = [System.Windows.Media.Brushes]::White

# Adiciona uma grid para layout
$Grid = New-Object System.Windows.Controls.Grid
$Grid.Margin = "10"
$Window.Content = $Grid

# Define as colunas e linhas da grid
$Grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition))
$Grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition))
$Grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
$Grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
$Grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
$Grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
$Grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))
$Grid.RowDefinitions.Add((New-Object System.Windows.Controls.RowDefinition))

# Caminho da logo
$logoPath = "https://jornada365.cloud/wp-content/uploads/2024/03/Logotipo-Jornada-365-Home.png"

# Adiciona a logo à janela
$Logo = New-Object System.Windows.Controls.Image
$Logo.Source = [System.Windows.Media.Imaging.BitmapImage]::new($logoPath)
$Logo.Width = 100
$Logo.Height = 100
$Logo.HorizontalAlignment = "Left"
$Logo.VerticalAlignment = "Top"
[System.Windows.Controls.Grid]::SetColumn($Logo, 0)
[System.Windows.Controls.Grid]::SetRow($Logo, 0)
$Grid.Children.Add($Logo)

# Criação do título centralizado
$TitleLabel = New-Object System.Windows.Controls.Label
$TitleLabel.Content = "Windows Features | Jornada 365"
$TitleLabel.HorizontalAlignment = "Center"
$TitleLabel.VerticalAlignment = "Top"
$TitleLabel.FontSize = 20
[System.Windows.Controls.Grid]::SetColumn($TitleLabel, 1)
[System.Windows.Controls.Grid]::SetRow($TitleLabel, 0)
$Grid.Children.Add($TitleLabel)

# GroupBox para pesquisa
$SearchGroupBox = New-Object System.Windows.Controls.GroupBox
$SearchGroupBox.Header = "Pesquisa de Features"
$SearchGroupBox.Margin = "10,10,10,10"
$SearchGroupBox.Padding = "10"
[System.Windows.Controls.Grid]::SetColumnSpan($SearchGroupBox, 2)
[System.Windows.Controls.Grid]::SetRow($SearchGroupBox, 1)
$Grid.Children.Add($SearchGroupBox)

$SearchGrid = New-Object System.Windows.Controls.Grid
$SearchGroupBox.Content = $SearchGrid

# Criação da TextBox para pesquisa
$TextBox = New-Object System.Windows.Controls.TextBox
$TextBox.Margin = "0,0,10,0"
$TextBox.VerticalAlignment = "Top"
$TextBox.Height = 25
$TextBox.Width = 300
[System.Windows.Controls.Grid]::SetColumn($TextBox, 0)
[System.Windows.Controls.Grid]::SetRow($TextBox, 0)
$SearchGrid.Children.Add($TextBox)

# Criação do botão de pesquisa
$ButtonSearch = New-Object System.Windows.Controls.Button
$ButtonSearch.Content = "Pesquisar"
$ButtonSearch.Margin = "0,0,0,0"
$ButtonSearch.HorizontalAlignment = "Right"
$ButtonSearch.VerticalAlignment = "Top"
$ButtonSearch.Width = 80
[System.Windows.Controls.Grid]::SetColumn($ButtonSearch, 1)
[System.Windows.Controls.Grid]::SetRow($ButtonSearch, 0)
$SearchGrid.Children.Add($ButtonSearch)

# GroupBox para exibir as features
$FeaturesGroupBox = New-Object System.Windows.Controls.GroupBox
$FeaturesGroupBox.Header = "Features Disponíveis"
$FeaturesGroupBox.Margin = "10,0,10,10"
$FeaturesGroupBox.Padding = "10"
[System.Windows.Controls.Grid]::SetColumnSpan($FeaturesGroupBox, 2)
[System.Windows.Controls.Grid]::SetRow($FeaturesGroupBox, 2)
$Grid.Children.Add($FeaturesGroupBox)

$FeaturesGrid = New-Object System.Windows.Controls.Grid
$FeaturesGroupBox.Content = $FeaturesGrid

# Criação da ListBox para exibir as features
$ListBox = New-Object System.Windows.Controls.ListBox
$ListBox.Margin = "0,0,0,10"
$ListBox.SelectionMode = "Multiple"
[System.Windows.Controls.Grid]::SetColumn($ListBox, 0)
[System.Windows.Controls.Grid]::SetRow($ListBox, 0)
$FeaturesGrid.Children.Add($ListBox)

# Criação da CheckBox para selecionar todas as features
$SelectAllCheckBox = New-Object System.Windows.Controls.CheckBox
$SelectAllCheckBox.Content = "Selecionar Todas"
$SelectAllCheckBox.Margin = "0,10,0,10"
$SelectAllCheckBox.HorizontalAlignment = "Left"
$SelectAllCheckBox.VerticalAlignment = "Top"
[System.Windows.Controls.Grid]::SetRow($SelectAllCheckBox, 1)
$FeaturesGrid.Children.Add($SelectAllCheckBox)

# Label para mostrar o total de features selecionadas
$SelectedCountLabel = New-Object System.Windows.Controls.Label
$SelectedCountLabel.Content = "Total de features selecionadas: 0"
$SelectedCountLabel.HorizontalAlignment = "Right"
$SelectedCountLabel.VerticalAlignment = "Top"
$SelectedCountLabel.Margin = "0,10,0,10"
[System.Windows.Controls.Grid]::SetRow($SelectedCountLabel, 2)
$FeaturesGrid.Children.Add($SelectedCountLabel)

# Botão para aplicar a seleção
$ButtonApply = New-Object System.Windows.Controls.Button
$ButtonApply.Content = "Aplicar"
$ButtonApply.Margin = "10,10,100,10"
$ButtonApply.HorizontalAlignment = "Right"
$ButtonApply.VerticalAlignment = "Bottom"
$ButtonApply.Width = 100
[System.Windows.Controls.Grid]::SetColumn($ButtonApply, 0)
[System.Windows.Controls.Grid]::SetRow($ButtonApply, 3)
$Grid.Children.Add($ButtonApply)

# Botão para fechar a janela
$ButtonClose = New-Object System.Windows.Controls.Button
$ButtonClose.Content = "Fechar"
$ButtonClose.Margin = "0,10,10,10"
$ButtonClose.HorizontalAlignment = "Right"
$ButtonClose.VerticalAlignment = "Bottom"
$ButtonClose.Width = 100
$ButtonClose.Add_Click({ $Window.Close() })
[System.Windows.Controls.Grid]::SetColumn($ButtonClose, 1)
[System.Windows.Controls.Grid]::SetRow($ButtonClose, 3)
$Grid.Children.Add($ButtonClose)

# Evento de pesquisa para filtrar as features mantendo as seleções anteriores
$ButtonSearch.Add_Click({
    Write-Log "Iniciando pesquisa de features."
    $SearchText = $TextBox.Text
    $FilteredFeatures = $CachedFeatures | Where-Object { $_ -like "*$SearchText*" }
    $ExistingSelections = @{}

    # Manter as seleções existentes
    foreach ($item in $ListBox.Items) {
        if ($item.IsChecked) {
            $ExistingSelections[$item.Content] = $true
        }
    }

    $ListBox.Items.Clear()
    foreach ($Feature in $FilteredFeatures) {
        $CheckBox = New-Object System.Windows.Controls.CheckBox
        $CheckBox.Content = $Feature

        # Manter seleção se já foi selecionada anteriormente
        if ($ExistingSelections.ContainsKey($Feature)) {
            $CheckBox.IsChecked = $true
        }

        $ListBox.Items.Add($CheckBox)
    }
    Write-Log "Pesquisa concluída com $($FilteredFeatures.Count) features encontradas."
    Update-SelectedCount
})

# Função para atualizar o total de features selecionadas
function Update-SelectedCount {
    $SelectedFeatures = $ListBox.Items | Where-Object { $_.IsChecked -eq $true }
    $SelectedCountLabel.Content = "Total de features selecionadas: $($SelectedFeatures.Count)"
}

# Evento para selecionar ou desmarcar todas as features
$SelectAllCheckBox.Add_Checked({
    foreach ($item in $ListBox.Items) {
        $item.IsChecked = $true
    }
    Write-Log "Todas as features foram selecionadas."
    Update-SelectedCount
})
$SelectAllCheckBox.Add_Unchecked({
    foreach ($item in $ListBox.Items) {
        $item.IsChecked = $false
    }
    Write-Log "Todas as features foram desmarcadas."
    Update-SelectedCount
})

# Evento para aplicar a seleção e salvar o script
$ButtonApply.Add_Click({
    Write-Log "Aplicando a seleção de features."
    $SelectedFeatures = $ListBox.Items | Where-Object { $_.IsChecked -eq $true }

    # Gera um nome aleatório baseado nas features selecionadas
    $GeneratedScriptName = Generate-RandomScriptName -SelectedFeatures $SelectedFeatures

    # Utilizando o SaveFileDialog do System.Windows.Forms
    $SaveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
    $SaveFileDialog.InitialDirectory = $scriptDirectory
    $SaveFileDialog.Filter = "PowerShell Script (*.ps1)|*.ps1"
    $SaveFileDialog.FileName = $GeneratedScriptName

    if ($SaveFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $ScriptContent = "Import-Module Wintune`n"
        foreach ($Feature in $SelectedFeatures) {
            $ScriptContent += "Enable-WindowsOptionalFeature -Online -FeatureName $Feature -All`n"
        }
        $ScriptContent | Out-File -FilePath $SaveFileDialog.FileName -Encoding UTF8
        Write-Log "Script salvo como $($SaveFileDialog.FileName)."
        [System.Windows.MessageBox]::Show("Script gerado com sucesso em $($SaveFileDialog.FileName)", "Sucesso", "OK", "Information")
    } else {
        Write-Log "Salvamento do script cancelado pelo usuário."
    }
})

# Exibe a janela
$Window.ShowDialog()

Write-Log "Script finalizado."
