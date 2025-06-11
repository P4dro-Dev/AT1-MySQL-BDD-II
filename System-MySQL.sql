-- Criação do banco de dados
CREATE DATABASE IF NOT EXISTS gestao_vendas;
USE gestao_vendas;

-- Criação das tabelas
CREATE TABLE IF NOT EXISTS vendedores (
    id_vendedor INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    data_contratacao DATE NOT NULL
);

CREATE TABLE IF NOT EXISTS produtos (
    id_produto INT AUTO_INCREMENT PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    preco DECIMAL(10,2) NOT NULL,
    estoque INT NOT NULL,
    categoria VARCHAR(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS vendas (
    id_venda INT AUTO_INCREMENT PRIMARY KEY,
    id_vendedor INT NOT NULL,
    id_produto INT NOT NULL,
    quantidade INT NOT NULL,
    data_venda DATE NOT NULL,
    valor_total DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (id_vendedor) REFERENCES vendedores(id_vendedor),
    FOREIGN KEY (id_produto) REFERENCES produtos(id_produto)
);

-- Inserção de dados de exemplo
INSERT INTO vendedores (nome, email, data_contratacao) VALUES
('João Silva', 'joao.silva@empresa.com', '2022-01-15'),
('Maria Santos', 'maria.santos@empresa.com', '2021-11-03'),
('Carlos Oliveira', 'carlos.oliveira@empresa.com', '2023-02-20'),
('Ana Pereira', 'ana.pereira@empresa.com', '2022-05-10');

INSERT INTO produtos (nome, preco, estoque, categoria) VALUES
('Notebook Elite', 4500.00, 15, 'Eletrônicos'),
('Smartphone Pro', 3200.00, 25, 'Eletrônicos'),
('Mesa de Escritório', 850.00, 10, 'Móveis'),
('Cadeira Ergonômica', 1200.00, 8, 'Móveis'),
('Teclado Sem Fio', 220.00, 30, 'Acessórios');

INSERT INTO vendas (id_vendedor, id_produto, quantidade, data_venda, valor_total) VALUES
(1, 1, 2, '2023-10-05', 9000.00),
(1, 3, 1, '2023-10-06', 850.00),
(2, 2, 3, '2023-10-05', 9600.00),
(2, 4, 2, '2023-10-07', 2400.00),
(3, 5, 5, '2023-10-08', 1100.00),
(4, 1, 1, '2023-10-09', 4500.00),
(4, 2, 2, '2023-10-10', 6400.00);

-- 1. Visão com todos os dados da tabela principal (vendas) mais duas colunas calculadas
CREATE OR REPLACE VIEW vw_detalhes_vendas AS
SELECT 
    v.*,
    p.nome AS nome_produto,
    p.preco AS preco_unitario,
    vd.nome AS nome_vendedor,
    -- Coluna calculada 1: comissão (5% do valor total)
    v.valor_total * 0.05 AS comissao,
    -- Coluna calculada 2: status da venda (baseado no valor)
    CASE 
        WHEN v.valor_total > 5000 THEN 'Alta'
        WHEN v.valor_total > 1000 THEN 'Média'
        ELSE 'Baixa'
    END AS status_venda
FROM 
    vendas v
JOIN 
    produtos p ON v.id_produto = p.id_produto
JOIN 
    vendedores vd ON v.id_vendedor = vd.id_vendedor;

-- 2. Visão filtrando somente um grupo (vendas de alta valor)
CREATE OR REPLACE VIEW vw_vendas_altas AS
SELECT * FROM vw_detalhes_vendas WHERE status_venda = 'Alta';

-- 3. Trigger para validar valores das vendas
DELIMITER //
CREATE TRIGGER tg_valida_venda
BEFORE INSERT ON vendas
FOR EACH ROW
BEGIN
    -- Verifica se a quantidade é positiva
    IF NEW.quantidade <= 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Quantidade deve ser maior que zero';
    END IF;
    
    -- Verifica se o valor total corresponde ao preço do produto x quantidade
    DECLARE preco_produto DECIMAL(10,2);
    SELECT preco INTO preco_produto FROM produtos WHERE id_produto = NEW.id_produto;
    
    IF ABS(NEW.valor_total - (preco_produto * NEW.quantidade)) > 0.01 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Valor total não corresponde ao preço do produto x quantidade';
    END IF;
END//
DELIMITER ;

-- 4. Procedimento para calcular a média geral de vendas
DELIMITER //
CREATE PROCEDURE sp_calcular_media_vendas(OUT media_vendas DECIMAL(10,2))
BEGIN
    SELECT AVG(valor_total) INTO media_vendas FROM vendas;
END//
DELIMITER ;

-- Exemplo de uso do procedimento
CALL sp_calcular_media_vendas(@media);
SELECT @media AS media_geral_vendas;